import 'package:logging/logging.dart';
import 'package:speedcube_ar/utils/logging_config.dart';
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/lbl_solver.dart';

void main() {
  initLogging();
  final log = Logger('TestStage5');
  final numTests = 100;
  int crossPassedCount = 0;
  int firstLayerPassedCount = 0;
  int secondLayerPassedCount = 0;
  int yellowCrossPassedCount = 0;
  int yellowEdgesPassedCount = 0;
  int yellowCornersPassedCount = 0;

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
    bool yellowCrossPassed = _checkYellowCross(finalState);
    bool yellowEdgesAligned = _checkYellowEdgesAligned(finalState, log);
    bool yellowCornersPassed = _checkYellowCorners(finalState, log);

    if (crossPassed) {
      crossPassedCount++;
    }
    if (firstLayerPassed) {
      firstLayerPassedCount++;
    }
    if (secondLayerPassed) {
      secondLayerPassedCount++;
    }
    if (yellowCrossPassed) {
      yellowCrossPassedCount++;
    }
    if (yellowEdgesAligned) {
      yellowEdgesPassedCount++;
    }
    if (yellowCornersPassed) {
      yellowCornersPassedCount++;
    }

    log.info(
        'Test $i: Cross: ${crossPassed ? "PASS" : "FAIL"}, F1: ${firstLayerPassed ? "PASS" : "FAIL"}, F2: ${secondLayerPassed ? "PASS" : "FAIL"}, Y-Cross: ${yellowCrossPassed ? "PASS" : "FAIL"}, Y-Edges: ${yellowEdgesAligned ? "PASS" : "FAIL"}, Y-Corners: ${yellowCornersPassed ? "PASS" : "FAIL"}');

    if (!yellowCornersPassed || !yellowEdgesAligned) {
      log.info(
          '  Scramble: ${scrambleMoves.map((m) => m.toString()).join(' ')}');
    }
  }

  log.info('\n=== Summary: $numTests tests ===');
  log.info('White Cross: $crossPassedCount / $numTests');
  log.info('First Layer: $firstLayerPassedCount / $numTests');
  log.info('Second Layer: $secondLayerPassedCount / $numTests');
  log.info('Yellow Cross: $yellowCrossPassedCount / $numTests');
  log.info('Yellow Edges: $yellowEdgesPassedCount / $numTests');
  log.info('Yellow Corners: $yellowCornersPassedCount / $numTests');
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
  if (!_checkFirstLayer(s)) {
    return false;
  }
  final middleFaces = [CubeFace.f, CubeFace.r, CubeFace.b, CubeFace.l];
  for (final f in middleFaces) {
    final face = s.getFace(f);
    if (face[3] != face[4] || face[5] != face[4]) {
      return false;
    }
  }
  return true;
}

bool _checkYellowCross(CubeState s) {
  if (!_checkSecondLayer(s)) {
    return false;
  }
  final yellowFace = _findCenterFace(s, CubeColor.yellow);
  final yellow = CubeColor.yellow;
  final f = s.getFace(yellowFace);
  return f[1] == yellow && f[3] == yellow && f[5] == yellow && f[7] == yellow;
}

bool _checkYellowEdgesAligned(CubeState s, Logger log) {
  if (!_checkYellowCross(s)) return false;
  final yellowFace = _findCenterFace(s, CubeColor.yellow);
  final neighbors = _getNeighbors(yellowFace);
  bool allMatch = true;
  for (final n in neighbors) {
    final sticker = s.getFace(n)[7];
    final center = s.getFace(n)[4];
    if (sticker != center) {
      allMatch = false;
      log.finer("    DEBUG Edge: $n index 7 is $sticker, center is $center");
    }
  }
  return allMatch;
}

bool _checkYellowCorners(CubeState s, Logger log) {
  if (!_checkYellowCross(s)) return false;
  final yellowFace = _findCenterFace(s, CubeColor.yellow);
  final yellow = CubeColor.yellow;

  // Try all 4 U rotations
  for (int turns = 0; turns < 4; turns++) {
    final rotated = s.applyMoves([CubeMove(yellowFace, turns)]);
    final f = rotated.getFace(yellowFace);

    // Check orientation
    if (f[0] == yellow && f[2] == yellow && f[6] == yellow && f[8] == yellow) {
      // Check position
      final neighbors = _getNeighbors(yellowFace);
      bool sidesMatch = true;
      for (final n in neighbors) {
        if (rotated.getFace(n)[6] != rotated.getFace(n)[4] ||
            rotated.getFace(n)[8] != rotated.getFace(n)[4]) {
          sidesMatch = false;
          break;
        }
      }
      if (sidesMatch) return true;
    }
  }

  // Debug orient/pos
  final f = s.getFace(yellowFace);
  log.finer(
      "    DEBUG: Yellow Orient: ${f[0] == yellow}, ${f[2] == yellow}, ${f[6] == yellow}, ${f[8] == yellow}");
  return false;
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
