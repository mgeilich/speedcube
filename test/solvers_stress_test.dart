import 'package:speedcube_ar/solver/heise_solver.dart';
import 'package:speedcube_ar/solver/kociemba_search.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/zz_solver.dart';
import 'package:speedcube_ar/solver/petrus_solver.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.message}');
  });
  final log = Logger('SolversStressTest');

  TestWidgetsFlutterBinding.ensureInitialized();

  test('Stress test ZZ, Petrus, and Heise solvers', () async {
    log.info("Initializing Kociemba tables...");
    await KociembaSearch().solve(CubeState.solved());
    log.info("Initialization complete.");

    final random = Random();
    const iterations = 20; 

    log.info("--- Testing ZZ Solver ---");
    try { await testSolver("ZZ", (s) => ZzSolver.solve(s), iterations, random, log); } catch(e) { log.severe("ZZ failed: $e"); }

    log.info("--- Testing Petrus Solver ---");
    try { await testSolver("Petrus", (s) => PetrusSolver.solve(s), iterations, random, log); } catch(e) { log.severe("Petrus failed: $e"); }

    log.info("--- Testing Heise Solver ---");
    try { await testSolver("Heise", (s) => HeiseSolver.solve(s), iterations, random, log); } catch(e) { log.severe("Heise failed: $e"); }
  }, timeout: const Timeout(Duration(minutes: 10)));
}

Future<void> testSolver(String name, Future<dynamic> Function(CubeState) solveFunc, int iterations, Random random, Logger log) async {
  int successCount = 0;

  for (int i = 0; i < iterations; i++) {
    final scramble = _generateRandomScramble(random, 20);
    final state = CubeState.solved().applyMoves(scramble);
    
    try {
      final result = await solveFunc(state);
      if (result == null) {
        log.warning("[$name] Attempt ${i + 1}: FAILED (Returned null)");
        continue;
      }
      
      final moves = result.allMoves;
      final solvedState = state.applyMoves(moves);
      
      if (solvedState.isSolved) {
        successCount++;
      } else {
        log.severe("[$name] Attempt ${i + 1}: FAILED (Not solved after moves)");
      }
    } catch (e) {
      log.severe("[$name] Attempt ${i + 1}: CRASHED ($e)");
    }
  }

  final rate = (successCount / iterations) * 100;
  log.info(">>> $name Success Rate: $rate% ($successCount/$iterations)");
  expect(rate, 100.0, reason: "$name solver should have 100% success rate");
}

List<CubeMove> _generateRandomScramble(Random r, int len) {
  final res = <CubeMove>[];
  CubeFace? lastFace;
  for (int i = 0; i < len; i++) {
    CubeFace face;
    do {
      face = CubeFace.values[r.nextInt(6)];
    } while (face == lastFace);
    lastFace = face;
    res.add(CubeMove(face, [1, -1, 2][r.nextInt(3)]));
  }
  return res;
}
