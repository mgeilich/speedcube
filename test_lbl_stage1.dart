// ignore_for_file: avoid_print
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/lbl_solver.dart';

void main() {
  final numTests = 100;
  int passedCount = 0;

  for (int i = 0; i < numTests; i++) {
    final scrambleMoves = CubeState.generateScramble(20);
    final scrambled = CubeState.solved().applyMoves(scrambleMoves);

    final result = LblSolver.solve(scrambled);
    if (result == null) {
      print('Test $i: FAIL - solver returned null');
      continue;
    }

    // We only care about moves up to White Cross
    final crossMoves = result.steps
        .where((s) => s.stageName == 'White Cross')
        .expand((s) => s.moves)
        .toList();

    final finalState = scrambled.applyMoves(crossMoves);
    if (_checkCross(finalState)) {
      passedCount++;
      // print('Test $i: PASS');
    } else {
      print('Test $i: FAIL');
      print('  Scramble: ${scrambleMoves.map((m) => m.toString()).join(' ')}');
    }
  }

  print('\n=== White Cross Summary: $passedCount / $numTests ===');
}

bool _checkCross(CubeState s) {
  // Find which face is white
  CubeFace? whiteFace;
  for (final f in CubeFace.values) {
    if (s.getFace(f)[4] == CubeColor.white) {
      whiteFace = f;
      break;
    }
  }
  if (whiteFace == null) return false;

  final white = CubeColor.white;
  final f = s.getFace(whiteFace);
  // Indices 1, 3, 5, 7 are edges
  if (f[1] != white || f[3] != white || f[5] != white || f[7] != white) {
    return false;
  }

  // Also check side alignment
  final neighbors = _getNeighbors(whiteFace);
  for (final neighbor in neighbors) {
    // Each neighbor's edge matching white face must match neighbor's center
    final idx = _getPhysicalEdgeIndex(neighbor, whiteFace);
    if (s.getFace(neighbor)[idx] != s.getFace(neighbor)[4]) return false;
  }

  return true;
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
