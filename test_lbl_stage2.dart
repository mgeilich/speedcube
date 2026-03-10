import 'package:logging/logging.dart';
import 'package:speedcube_ar/utils/logging_config.dart';
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/lbl_solver.dart';

void main() {
  initLogging();
  final log = Logger('TestStage2');

  final numTests = 20;
  int crossPassedCount = 0;
  int firstLayerPassedCount = 0;

  for (int i = 0; i < numTests; i++) {
    final scrambleMoves = CubeState.generateScramble(20);
    final scrambled = CubeState.solved().applyMoves(scrambleMoves);

    final result = LblSolver.solve(scrambled);
    if (result == null) {
      log.severe('Test $i: FAIL - solver returned null');
      continue;
    }

    final relevantMoves = result.steps
        .where(
            (s) => s.stageName == 'White Cross' || s.stageName == 'First Layer')
        .expand((s) => s.moves)
        .toList();

    final finalState = scrambled.applyMoves(relevantMoves);
    bool crossPassed = _checkCross(finalState);
    bool firstLayerPassed = _checkFirstLayer(finalState);

    if (crossPassed) {
      crossPassedCount++;
    }
    if (firstLayerPassed) {
      firstLayerPassedCount++;
    }

    log.info(
        'Test $i: Cross: ${crossPassed ? "PASS" : "FAIL"}, First Layer: ${firstLayerPassed ? "PASS" : "FAIL"}');

    if (!crossPassed) {
      log.info(
          '  Scramble: ${scrambleMoves.map((m) => m.toString()).join(' ')}');
      log.info(
          '  Moves: ${result.allMoves.map((m) => m.toString()).join(' ')}');
      _printFailureDetails(scrambled, result, 'White Cross', log);
    } else if (!firstLayerPassed) {
      log.info(
          '  Scramble: ${scrambleMoves.map((m) => m.toString()).join(' ')}');
      log.info(
          '  Moves: ${result.allMoves.map((m) => m.toString()).join(' ')}');
      _printFailureDetails(scrambled, result, 'First Layer', log);
    }
  }

  log.info('\n=== Summary: $numTests tests ===');
  log.info('White Cross: $crossPassedCount / $numTests');
  log.info('First Layer: $firstLayerPassedCount / $numTests');
}

bool _checkCross(CubeState s) {
  final whiteFace = _findCenterFace(s, CubeColor.white);
  final white = CubeColor.white;

  // Check U-equivalent (the white face itself)
  if (s.getFace(whiteFace)[1] != white ||
      s.getFace(whiteFace)[3] != white ||
      s.getFace(whiteFace)[5] != white ||
      s.getFace(whiteFace)[7] != white) {
    return false;
  }

  // Neighbors logic to check side colors
  final neighbors = _getNeighbors(whiteFace);
  for (final neighbor in neighbors) {
    // Standard LBL check: edge sticker matches center
    final idx = _getPhysicalEdgeIndex(neighbor, whiteFace);
    if (s.getFace(neighbor)[idx] != s.getFace(neighbor)[4]) {
      return false;
    }
  }
  return true;
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

bool _checkFirstLayer(CubeState s) {
  if (!_checkCross(s)) return false;
  final whiteFace = _findCenterFace(s, CubeColor.white);
  final white = CubeColor.white;

  // Corners on white face
  final f = s.getFace(whiteFace);
  if (f[0] != white || f[2] != white || f[6] != white || f[8] != white) {
    return false;
  }

  // Neighbors corners
  final neighbors = _getNeighbors(whiteFace);
  for (final n in neighbors) {
    if (s.getFace(n)[0] != s.getFace(n)[4] ||
        s.getFace(n)[2] != s.getFace(n)[4]) {
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
  // Return neighbors in CW order around face f
  if (f == CubeFace.u) return [CubeFace.b, CubeFace.r, CubeFace.f, CubeFace.l];
  if (f == CubeFace.d) return [CubeFace.f, CubeFace.r, CubeFace.b, CubeFace.l];
  if (f == CubeFace.f) return [CubeFace.u, CubeFace.r, CubeFace.d, CubeFace.l];
  if (f == CubeFace.b) return [CubeFace.u, CubeFace.l, CubeFace.d, CubeFace.r];
  if (f == CubeFace.r) return [CubeFace.u, CubeFace.b, CubeFace.d, CubeFace.f];
  if (f == CubeFace.l) return [CubeFace.u, CubeFace.f, CubeFace.d, CubeFace.b];
  return [];
}

void _printFailureDetails(
    CubeState scrambled, LblSolveResult result, String stage, Logger log) {
  final s = scrambled.applyMoves(result.allMoves);
  log.info('    U (Top) stickers: ${s.u}');
  log.info(
      '    Sides row 1: F:${s.f[1]}, R:${s.r[1]}, B:${s.b[1]}, L:${s.l[1]}');
  log.info(
      '    Sides centers: F:${s.f[4]}, R:${s.r[4]}, B:${s.b[4]}, L:${s.l[4]}');
}
