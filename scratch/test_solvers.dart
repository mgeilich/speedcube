// ignore_for_file: avoid_print
import 'dart:math';
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/zz_solver.dart';
import 'package:speedcube_ar/solver/petrus_solver.dart';
import 'package:speedcube_ar/solver/heise_solver.dart';
import 'package:speedcube_ar/solver/kociemba_search.dart';

Future<void> main() async {
  print("Initializing Kociemba tables...");
  await KociembaSearch().solve(CubeState.solved());

  final random = Random();
  const iterations = 20;

  print("\n--- Testing ZZ Solver ---");
  await testSolver("ZZ", (s) => ZzSolver.solve(s), iterations, random);

  print("\n--- Testing Petrus Solver ---");
  await testSolver("Petrus", (s) => PetrusSolver.solve(s), iterations, random);

  print("\n--- Testing Heise Solver ---");
  await testSolver("Heise", (s) => HeiseSolver.solve(s), iterations, random);
}

Future<void> testSolver(String name, Future<dynamic> Function(CubeState) solveFunc, int iterations, Random random) async {
  int successCount = 0;

  for (int i = 0; i < iterations; i++) {
    final scramble = _generateRandomScramble(random, 20);
    final state = CubeState.solved().applyMoves(scramble);
    
    try {
      final result = await solveFunc(state);
      if (result == null) {
        print("[$name] Attempt ${i + 1}: FAILED (Returned null)");
        continue;
      }
      
      final moves = result.allMoves;
      final solvedState = state.applyMoves(moves);
      
      if (solvedState.isSolved) {
        successCount++;
        // print("[$name] Attempt ${i + 1}: SUCCESS (${moves.length} moves)");
      } else {
        print("[$name] Attempt ${i + 1}: FAILED (Not solved after moves)");
      }
    } catch (e) {
      print("[$name] Attempt ${i + 1}: CRASHED ($e)");
    }
  }

  final rate = (successCount / iterations) * 100;
  print(">>> $name Success Rate: $rate% ($successCount/$iterations)");
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
