import 'package:logging/logging.dart';
import 'lib/utils/logging_config.dart';
import 'lib/models/cube_state.dart';
import 'lib/models/cube_move.dart';
import 'lib/solver/lbl_solver.dart';

void main() {
  initLogging();
  final log = Logger('TestSolved');

  final initial = CubeState.solved().applyMoves(CubeState.generateScramble(20));
  log.info('Solving White Cross for scrambled cube...');

  // 1. Orient
  final whiteFace = _findCenterFace(initial, CubeColor.white);
  var state = _orientFaceToTop(initial, whiteFace);
  _checkIntegrity(state, log);

  // 2. Solve White Cross
  final result = LblSolver.solve(initial);
  if (result == null) {
    return;
  }

  final crossSteps =
      result.steps.where((s) => s.stageName == 'White Cross').toList();
  for (final step in crossSteps) {
    state = state.applyMoves(step.moves);
    _checkIntegrity(state, log);
  }

  final crossOk = _isWhiteCrossComplete(state);
  log.info('White Cross: ${crossOk ? "PASS" : "FAIL"}');
}

CubeFace _findCenterFace(CubeState s, CubeColor c) {
  for (final f in CubeFace.values) {
    if (s.getFace(f)[4] == c) {
      return f;
    }
  }
  return CubeFace.d;
}

bool _isWhiteCrossComplete(CubeState s) {
  if (s.u[1] != CubeColor.white ||
      s.u[3] != CubeColor.white ||
      s.u[5] != CubeColor.white ||
      s.u[7] != CubeColor.white) {
    return false;
  }
  return true;
}

void _checkIntegrity(CubeState s, Logger log) {
  for (final (f1, i1, f2, i2, f3, i3) in _allCorners) {
    final colors = {s.getFace(f1)[i1], s.getFace(f2)[i2], s.getFace(f3)[i3]};
    if (colors.length < 3) {
      log.severe(
          'INTEGRITY ERROR: Corner $f1-$i1, $f2-$i2, $f3-$i3 has duplicate colors: $colors');
    }
  }
}

const _allCorners = [
  (CubeFace.u, 6, CubeFace.f, 0, CubeFace.l, 2),
  (CubeFace.u, 8, CubeFace.r, 0, CubeFace.f, 2),
  (CubeFace.u, 2, CubeFace.b, 0, CubeFace.r, 2),
  (CubeFace.u, 0, CubeFace.l, 0, CubeFace.b, 2),
  (CubeFace.d, 0, CubeFace.l, 8, CubeFace.f, 6),
  (CubeFace.d, 2, CubeFace.f, 8, CubeFace.r, 6),
  (CubeFace.d, 8, CubeFace.r, 8, CubeFace.b, 6),
  (CubeFace.d, 6, CubeFace.b, 8, CubeFace.l, 6),
];

CubeState _orientFaceToTop(CubeState s, CubeFace target) {
  // Copy of the logic from LblSolver to prepare the test state
  if (target == CubeFace.f) {
    return CubeState.fromFaces(
        u: s.f, d: s.b, f: s.d, b: s.u, r: _rotateCW(s.r), l: _rotateCCW(s.l));
  }
  return s;
}

List<CubeColor> _rotateCW(List<CubeColor> f) {
  final r = List<CubeColor>.from(f);
  r[0] = f[6];
  r[1] = f[3];
  r[2] = f[0];
  r[3] = f[7];
  r[4] = f[4];
  r[5] = f[1];
  r[6] = f[8];
  r[7] = f[5];
  r[8] = f[2];
  return r;
}

List<CubeColor> _rotateCCW(List<CubeColor> f) {
  final r = List<CubeColor>.from(f);
  r[0] = f[2];
  r[1] = f[5];
  r[2] = f[8];
  r[3] = f[1];
  r[4] = f[4];
  r[5] = f[7];
  r[6] = f[0];
  r[7] = f[3];
  r[8] = f[6];
  return r;
}
