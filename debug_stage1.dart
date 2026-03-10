// ignore_for_file: avoid_print
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/lbl_solver.dart';

void main() {
  final scrambleStr = "L U' B L R' L' U R' B D' B' R U F L' B L' D' L' R";
  final scrambleMoves =
      scrambleStr.split(' ').map((s) => CubeMove.parse(s)!).toList();
  final scrambled = CubeState.solved().applyMoves(scrambleMoves);

  print('Scrambled State:');
  _dumpState(scrambled);

  final result = LblSolver.solve(scrambled);
  if (result == null) {
    print('Solver returned null');
    return;
  }

  print('\nSteps:');
  var currentS = scrambled;
  for (final step in result.steps) {
    if (step.stageName == 'White Cross') {
      print('--- ${step.stageName}: ${step.description} ---');
      print('Moves: ${step.moves}');
      currentS = currentS.applyMoves(step.moves);
      _dumpState(currentS);
    }
  }

  if (_checkCross(currentS)) {
    print('\nCROSS SOLVED!');
  } else {
    print('\nCROSS FAILED!');
  }
}

void _dumpState(CubeState s) {
  for (final face in CubeFace.values) {
    print('${face.name}: ${s.getFace(face)}');
  }
}

bool _checkCross(CubeState s) {
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
  print('Checking Cross on face ${whiteFace.name}:');
  print('  Edges: ${f[1]}, ${f[3]}, ${f[5]}, ${f[7]}');
  if (f[1] != white || f[3] != white || f[5] != white || f[7] != white) {
    return false;
  }

  final neighbors = _getNeighbors(whiteFace);
  for (final neighbor in neighbors) {
    final idx = _getPhysicalEdgeIndex(neighbor, whiteFace);
    print(
        '  Neighbor ${neighbor.name} edge: ${s.getFace(neighbor)[idx]} (center: ${s.getFace(neighbor)[4]})');
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
