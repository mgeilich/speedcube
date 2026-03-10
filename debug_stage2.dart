// ignore_for_file: avoid_print
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/lbl_solver.dart';

void main() {
  // Use a failed scramble from Step 2 run
  final scrambleStr = "U R L' R' D' F L D' U B F D' R U' B' D' U L' F R";
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

  print('\nStep-by-Step Analysis:');
  var currentS = scrambled;
  for (final step in result.steps) {
    print('--- ${step.stageName}: ${step.description} ---');
    print('Moves: ${step.moves}');
    currentS = currentS.applyMoves(step.moves);

    if (step.stageName == 'White Cross') {
      // cross should be good
    } else if (step.stageName == 'First Layer') {
      _inspectFirstLayerState(currentS);
    }

    if (step.stageName == 'First Layer' && !_checkCrossSafe(currentS)) {
      print('WARNING: Cross BROKEN!');
    }
  }

  if (_checkFirstLayer(currentS)) {
    print('\nSTSTAGE 2 SOLVED!');
  } else {
    print('\nSTAGE 2 FAILED!');
  }
}

void _dumpState(CubeState s) {
  for (final face in CubeFace.values) {
    print('${face.name}: ${s.getFace(face)}');
  }
}

void _inspectFirstLayerState(CubeState s) {
  CubeFace? whiteFace;
  for (final f in CubeFace.values) {
    if (s.getFace(f)[4] == CubeColor.white) {
      whiteFace = f;
      break;
    }
  }
  if (whiteFace == null) return;

  final f = s.getFace(whiteFace);
  print('  White face (${whiteFace.name}): $f');
  print('  Corners: 0:${f[0]}, 2:${f[2]}, 6:${f[6]}, 8:${f[8]}');
}

bool _checkCrossSafe(CubeState s) {
  final whiteFace = _findCenterFace(s, CubeColor.white);
  final white = CubeColor.white;
  if (s.getFace(whiteFace)[1] != white ||
      s.getFace(whiteFace)[3] != white ||
      s.getFace(whiteFace)[5] != white ||
      s.getFace(whiteFace)[7] != white) {
    return false;
  }
  return true;
}

bool _checkFirstLayer(CubeState s) {
  final whiteFace = _findCenterFace(s, CubeColor.white);
  final white = CubeColor.white;
  final f = s.getFace(whiteFace);
  if (f[0] != white || f[2] != white || f[6] != white || f[8] != white) {
    return false;
  }
  if (!_checkCrossSafe(s)) return false;
  return true;
}

CubeFace _findCenterFace(CubeState s, CubeColor c) {
  for (final f in CubeFace.values) {
    if (s.getFace(f)[4] == c) return f;
  }
  return CubeFace.u;
}
