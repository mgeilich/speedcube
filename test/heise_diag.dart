// ignore_for_file: avoid_print
// Diagnostic: which Heise stage fails, per orientation, over seeded scrambles.
// Run: flutter test test/heise_diag.dart

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/solver/heise_solver.dart';
import 'package:speedcube_ar/solver/kociemba_coordinates.dart';
import 'package:speedcube_ar/solver/kociemba_tables.dart';

List<CubeMove> scramble(Random r, int len) {
  final res = <CubeMove>[];
  CubeFace? last;
  for (int i = 0; i < len; i++) {
    CubeFace f;
    do {
      f = CubeFace.physicalFaces[r.nextInt(6)];
    } while (f == last);
    last = f;
    res.add(CubeMove(f, [1, -1, 2][r.nextInt(3)]));
  }
  return res;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('heise stage diagnostics', () async {
    await KociembaTables.init();
    const n = int.fromEnvironment('N', defaultValue: 40);
    final failsByStage = <int, int>{};
    int solvedTop4 = 0;
    final stageMs = <int, int>{};

    for (int seed = 0; seed < n; seed++) {
      final initial = CubeState.solved().applyMoves(scramble(Random(seed), 20));
      final orientations = HeiseSolver.generateAll24Rotations();
      orientations.sort((a, b) => HeiseSolver.scoreHeiseOrientation(initial.applyMoves(b))
          .compareTo(HeiseSolver.scoreHeiseOrientation(initial.applyMoves(a))));
      bool ok = false;
      final perOrient = <String>[];
      for (int o = 0; o < 4; o++) {
        var s = initial.applyMoves(orientations[o]);
        int failed = 0;
        final stages = <dynamic Function(CubeState)>[
          (s) => HeiseSolver.solve2x2x2Isolate(KociembaCube.fromCubeState(s).toData()),
          (s) => HeiseSolver.solve2x2x3Isolate(KociembaCube.fromCubeState(s).toData()),
          (s) => HeiseSolver.solveTwoSquaresIsolate(KociembaCube.fromCubeState(s).toData()),
          (s) => HeiseSolver.solveEOIsolate(KociembaCube.fromCubeState(s).toData()),
          (s) => HeiseSolver.solveEdgesAndTwoCornersIsolate({'state': s, 'tables': KociembaTables.data}),
        ];
        for (int i = 0; i < stages.length; i++) {
          final sw = Stopwatch()..start();
          var m = stages[i](s);
          if (m is Future) m = await m;
          stageMs[i + 1] = (stageMs[i + 1] ?? 0) + sw.elapsedMilliseconds;
          if (m == null) {
            failed = i + 1;
            break;
          }
          s = s.applyMoves(m as List<CubeMove>);
        }
        if (failed == 0) {
          final r6 = await HeiseSolver.solveThreeCornerCommutatorIsolate({'state': s, 'tables': KociembaTables.data});
          if (r6 == null) {
            failed = 6;
          } else {
            final k5 = KociembaCube.fromCubeState(s);
            final before = 'edges=${k5.isEdgeSolved} corners=${k5.unsolvedCornerCount}';
            s = s.applyMoves(r6['moves'] as List<CubeMove>);
            if (!s.isSolved) {
              failed = 7;
              final k6 = KociembaCube.fromCubeState(s);
              print('  S7 seed $seed o$o: after S5 $before; comm=${r6['isCommutator']} '
                  'after S6 kSolved=${k6.isSolved} edges=${k6.isEdgeSolved} corners=${k6.unsolvedCornerCount} '
                  'centersStd=${s.u[4]},${s.f[4]}');
            }
          }
        }
        perOrient.add(failed == 0 ? 'ok' : 'S$failed');
        if (failed == 0) {
          ok = true;
          break;
        }
        failsByStage[failed] = (failsByStage[failed] ?? 0) + 1;
      }
      if (ok) solvedTop4++;
      print('seed $seed: ${perOrient.join(' ')}');
    }
    print('Solved within top-4 orientations: $solvedTop4/$n');
    print('Failures by stage (7 = not solved after stage 6): $failsByStage');
    print('Total ms by stage: $stageMs');
  }, timeout: const Timeout(Duration(minutes: 30)));

  // Run: flutter test test/heise_diag.dart --plain-name "heise end-to-end" --dart-define=E2E=100
  test('heise end-to-end', () async {
    await KociembaTables.init();
    const n = int.fromEnvironment('E2E', defaultValue: 0);
    int solved = 0, maxMs = 0, totalMs = 0;
    for (int seed = 1000; seed < 1000 + n; seed++) {
      final state = CubeState.solved().applyMoves(scramble(Random(seed), 20));
      final sw = Stopwatch()..start();
      final result = await HeiseSolver.solve(state);
      final ms = sw.elapsedMilliseconds;
      totalMs += ms;
      if (ms > maxMs) maxMs = ms;
      if (state.applyMoves(result.allMoves).isSolved) {
        solved++;
      } else {
        print('E2E FAIL seed $seed');
      }
    }
    if (n > 0) print('E2E solved $solved/$n, avg ${totalMs ~/ n} ms, max $maxMs ms');
  }, timeout: const Timeout(Duration(minutes: 60)));
}
