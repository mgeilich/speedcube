import 'package:logging/logging.dart';
import 'lib/utils/logging_config.dart';
import 'lib/models/cube_state.dart';
import 'lib/models/cube_move.dart';
import 'lib/solver/lbl_solver.dart';

void main() {
  initLogging();
  final log = Logger('TestStage3');

  final numTests = 20;
  int crossPassedCount = 0;
  int firstLayerPassedCount = 0;
  int secondLayerPassedCount = 0;

  for (int i = 0; i < numTests; i++) {
    final scrambleMoves = CubeState.generateScramble(20);
    final scrambled = CubeState.solved().applyMoves(scrambleMoves);

    final result = LblSolver.solve(scrambled);
    if (result == null) {
      log.severe('Test $i: FAIL - solver returned null');
      continue;
    }

    final finalState = scrambled.applyMoves(result.allMoves);
    bool crossPassed = _checkCross(finalState);
    bool firstLayerPassed = _checkFirstLayer(finalState);
    bool secondLayerPassed = _checkSecondLayer(finalState);

    if (crossPassed) {
      crossPassedCount++;
    }
    if (firstLayerPassed) {
      firstLayerPassedCount++;
    }
    if (secondLayerPassed) {
      secondLayerPassedCount++;
    }

    log.info(
        'Test $i: Cross: ${crossPassed ? "PASS" : "FAIL"}, First Layer: ${firstLayerPassed ? "PASS" : "FAIL"}, Second Layer: ${secondLayerPassed ? "PASS" : "FAIL"}');

    if (!secondLayerPassed) {
      log.info(
          '  Scramble: ${scrambleMoves.map((m) => m.toString()).join(' ')}');
    }
  }

  log.info('\n=== Summary: $numTests tests ===');
  log.info('White Cross: $crossPassedCount / $numTests');
  log.info('First Layer: $firstLayerPassedCount / $numTests');
  log.info('Second Layer: $secondLayerPassedCount / $numTests');
}

bool _checkCross(CubeState s) {
  final whiteFace = _findCenterFace(s, CubeColor.white);
  final white = CubeColor.white;

  if (s.getFace(whiteFace)[1] != white ||
      s.getFace(whiteFace)[3] != white ||
      s.getFace(whiteFace)[5] != white ||
      s.getFace(whiteFace)[7] != white) {
    return false;
  }

  final neighbors = _getNeighbors(whiteFace);
  for (final neighbor in neighbors) {
    final idx = _getPhysicalEdgeIndex(neighbor, whiteFace);
    if (s.getFace(neighbor)[idx] != s.getFace(neighbor)[4]) {
      return false;
    }
  }
  return true;
}

bool _checkFirstLayer(CubeState s) {
  if (!_checkCross(s)) return false;
  final whiteFace = _findCenterFace(s, CubeColor.white);
  final white = CubeColor.white;

  final f = s.getFace(whiteFace);
  if (f[0] != white || f[2] != white || f[6] != white || f[8] != white) {
    return false;
  }

  final neighbors = _getNeighbors(whiteFace);
  for (final n in neighbors) {
    if (s.getFace(n)[0] != s.getFace(n)[4] ||
        s.getFace(n)[2] != s.getFace(n)[4]) {
      return false;
    }
  }
  return true;
}

bool _checkSecondLayer(CubeState s) {
  if (!_checkFirstLayer(s)) return false;

  // White is on bottom (standard LBL test convention)
  // Middle layer edges: check if they match their centers
  final middleFaces = [CubeFace.f, CubeFace.r, CubeFace.b, CubeFace.l];
  for (int i = 0; i < 4; i++) {
    final f1 = middleFaces[i];

    // We can just check the middle row (3, 4, 5) on all middle faces
    final face = s.getFace(f1);
    if (face[3] != face[4] || face[5] != face[4]) {
      return false;
    }
  }

  return true;
}

CubeFace _findCenterFace(CubeState s, CubeColor c) {
  for (final f in CubeFace.values) {
    if (s.getFace(f)[4] == c) {
      return f;
    }
  }
  return CubeFace.u;
}

List<CubeFace> _getNeighbors(CubeFace f) {
  if (f == CubeFace.u) return [CubeFace.b, CubeFace.r, CubeFace.f, CubeFace.l];
  if (f == CubeFace.d) return [CubeFace.f, CubeFace.r, CubeFace.b, CubeFace.l];
  if (f == CubeFace.f) return [CubeFace.u, CubeFace.r, CubeFace.d, CubeFace.l];
  if (f == CubeFace.b) return [CubeFace.u, CubeFace.l, CubeFace.d, CubeFace.r];
  if (f == CubeFace.r) return [CubeFace.u, CubeFace.b, CubeFace.d, CubeFace.f];
  if (f == CubeFace.l) return [CubeFace.u, CubeFace.f, CubeFace.d, CubeFace.b];
  return [];
}

int _getPhysicalEdgeIndex(CubeFace f, CubeFace neighbor) {
  // Same as in test_lbl_stage2.dart
  if (f == CubeFace.u) {
    return neighbor == CubeFace.b
        ? 1
        : (neighbor == CubeFace.f ? 7 : (neighbor == CubeFace.l ? 3 : 5));
  }
  if (f == CubeFace.d) {
    return neighbor == CubeFace.f
        ? 1
        : (neighbor == CubeFace.b ? 7 : (neighbor == CubeFace.l ? 3 : 5));
  }
  if (f == CubeFace.f) {
    return neighbor == CubeFace.u
        ? 1
        : (neighbor == CubeFace.d ? 7 : (neighbor == CubeFace.l ? 3 : 5));
  }
  if (f == CubeFace.b) {
    return neighbor == CubeFace.u
        ? 1
        : (neighbor == CubeFace.d ? 7 : (neighbor == CubeFace.r ? 3 : 5));
  }
  if (f == CubeFace.r) {
    return neighbor == CubeFace.u
        ? 1
        : (neighbor == CubeFace.d ? 7 : (neighbor == CubeFace.f ? 3 : 5));
  }
  if (f == CubeFace.l) {
    return neighbor == CubeFace.u
        ? 1
        : (neighbor == CubeFace.d ? 7 : (neighbor == CubeFace.b ? 3 : 5));
  }
  return 4;
}
