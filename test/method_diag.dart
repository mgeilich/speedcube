// ignore_for_file: avoid_print
// Diagnostic: success rate and timing of every solve method over seeded
// scrambles, through SolverService exactly as the app calls it.
// Run: flutter test test/method_diag.dart --dart-define=N=30

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/solve_method.dart';
import 'package:speedcube_ar/services/solver_service.dart';

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
  test('all methods', () async {
    const n = int.fromEnvironment('N', defaultValue: 30);
    const only = String.fromEnvironment('METHOD');
    for (final method in SolveMethod.values) {
      if (only.isNotEmpty && method.name != only) continue;
      int ok = 0, maxMs = 0, totalMs = 0;
      final failedSeeds = <int>[];
      for (int seed = 0; seed < n; seed++) {
        final state = CubeState.solved().applyMoves(scramble(Random(seed), 20));
        final sw = Stopwatch()..start();
        var solved = false;
        try {
          final r = await SolverService.solve(state: state, method: method);
          solved = r.moves.isNotEmpty && state.applyMoves(r.moves).isSolved;
        } catch (e) {
          print('${method.name} seed $seed threw: $e');
        }
        final ms = sw.elapsedMilliseconds;
        totalMs += ms;
        if (ms > maxMs) maxMs = ms;
        if (solved) {
          ok++;
        } else {
          failedSeeds.add(seed);
        }
      }
      print('RESULT ${method.name}: $ok/$n solved, avg ${totalMs ~/ n} ms, '
          'max $maxMs ms${failedSeeds.isEmpty ? '' : ', failed seeds $failedSeeds'}');
    }
  }, timeout: const Timeout(Duration(minutes: 60)));
}
