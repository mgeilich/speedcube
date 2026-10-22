// ignore_for_file: avoid_print
// Diagnostic: which Roux stage fails, and how long each takes, per orientation.
// Run: flutter test test/roux_diag.dart --dart-define=SEEDS=4,8,13

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/solver/roux_solver.dart';

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
  test('roux stages', () async {
    const seedsArg = String.fromEnvironment('SEEDS', defaultValue: '4,8,13');
    const orients = int.fromEnvironment('ORIENTS', defaultValue: 6);
    for (final seed in seedsArg.split(',').map(int.parse)) {
      final initial = CubeState.solved().applyMoves(scramble(Random(seed), 20));
      final orientations = RouxSolver.generateAll24Rotations();
      orientations.sort((a, b) => RouxSolver.scoreOrientation(initial.applyMoves(b))
          .compareTo(RouxSolver.scoreOrientation(initial.applyMoves(a))));
      final parts = <String>[];
      for (int o = 0; o < orients; o++) {
        var s = initial.applyMoves(orientations[o]);
        final dRef = s.d[4];
        final sw = Stopwatch()..start();
        String outcome = 'ok';
        final fb = RouxSolver.findFBRealistic(s);
        final tFb = sw.elapsedMilliseconds;
        if (fb == null) {
          outcome = 'FB';
        } else {
          s = s.applyMoves(fb.expand((st) => st.moves).toList());
          final sb = RouxSolver.solveSBRealistic(s);
          if (sb == null) {
            outcome = 'SB';
          } else {
            s = s.applyMoves(sb.expand((st) => st.moves).toList());
            outcome = 'mAligned=${s.d[4] == dRef} ';
            final cmll = RouxSolver.findCMLL(s);
            if (cmll == null) {
              outcome += 'CMLL';
            } else {
              s = s.applyMoves(cmll);
              final lse = RouxSolver.solveLSE(s);
              if (lse == null) {
                outcome += 'LSE';
              } else {
                s = s.applyMoves(lse.expand((st) => st.moves).toList());
                outcome += s.isSolved ? 'ok' : 'NOTSOLVED';
              }
            }
          }
        }
        parts.add('$outcome(fb ${tFb}ms, total ${sw.elapsedMilliseconds}ms)');
      }
      print('ROUX seed $seed: ${parts.join(' | ')}');
    }
  }, timeout: const Timeout(Duration(minutes: 60)));
}
