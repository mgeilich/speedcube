// ignore_for_file: avoid_print
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/zz_solver.dart';
import 'package:speedcube_ar/solver/petrus_solver.dart';
import 'package:speedcube_ar/solver/heise_solver.dart';
import 'package:speedcube_ar/solver/kociemba_search.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  print("Init...");
  await KociembaSearch().solve(CubeState.solved());
  print("Done.\n");

  final r = Random(42);

  Future<void> test(String name, Future<dynamic> Function(CubeState) fn) async {
    print("--- $name ---");
    int ok = 0;
    for (int i = 0; i < 5; i++) {
      CubeFace? last;
      final scramble = <CubeMove>[];
      for (int j = 0; j < 20; j++) {
        CubeFace face;
        do { face = CubeFace.values[r.nextInt(6)]; } while (face == last);
        last = face;
        scramble.add(CubeMove(face, [1,-1,2][r.nextInt(3)]));
      }
      final state = CubeState.solved().applyMoves(scramble);
      try {
        final result = await fn(state);
        if (result == null) { print("  [$i] null"); continue; }
        final moves = result.allMoves as List<CubeMove>;
        final finalState = state.applyMoves(moves);
        if (finalState.isSolved) {
          ok++;
          final stepStr = result.steps.map((s) => '${s.stageName}(${s.moves.length})').join(' | ');
          print("  [$i] OK (${moves.length} moves): $stepStr");
        } else {
          final steps = result.steps;
          print("  [$i] FAIL: ${moves.length} moves, steps: ${steps.map((s) => '${s.stageName}(${s.moves.length})').join(' | ')}");
          // Trace which step breaks it
          var cs = state;
          for (final step in steps) {
            cs = cs.applyMoves(step.moves);
            print("      After '${step.stageName}': solved=${cs.isSolved}");
          }
        }
      } catch (e, stack) { print("  [$i] CRASH: $e\n    $stack"); }
    }
    print("  => $ok/5\n");
  }

  await test("ZZ", (s) => ZzSolver.solve(s));
  await test("Petrus", (s) => PetrusSolver.solve(s));
  await test("Heise", (s) => HeiseSolver.solve(s));
}
