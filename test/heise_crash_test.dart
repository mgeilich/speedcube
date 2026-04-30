import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/heise_solver.dart';
import 'package:speedcube_ar/solver/kociemba_search.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  final log = Logger('HeiseCrashTest');

  TestWidgetsFlutterBinding.ensureInitialized();

  test('Quick Heise crash test', () async {
    log.info("Initializing...");
    await KociembaSearch().solve(CubeState.solved());

    final random = Random();
    for (int i = 0; i < 50; i++) {
      final scramble = _generateRandomScramble(random, 20);
      final state = CubeState.solved().applyMoves(scramble);
      
      try {
        log.info("Attempt ${i + 1}...");
        final result = await HeiseSolver.solve(state);
        if (result.steps.isEmpty) {
          log.warning("  FAILED (No solution)");
        } else {
          final solvedState = state.applyMoves(result.allMoves);
          if (solvedState.isSolved) {
            log.info("  SUCCESS");
          } else {
            log.severe("  FAILED (Not solved)");
          }
        }
      } catch (e, stack) {
        log.severe("  CRASHED ($e)", e, stack);
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
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
