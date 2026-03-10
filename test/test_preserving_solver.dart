import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/piece_path_solver.dart';
import 'package:speedcube_ar/utils/logging_config.dart';
import 'package:logging/logging.dart';

final _log = Logger('PreservingSolverTest');

void main() {
  initLogging();
  _log.info('Testing findPreservingPath...');

  // Scenario: White Cross
  // 3 white edges are already at U3, U5, U7.
  // 4th white edge is at F7.
  // Goal: Move F7 to U1 without disturbing U3, U5, U7.

  final initialState = CubeState.solved();
  // Mess it up a bit first
  initialState.u[1] = CubeColor.yellow;
  initialState.f[7] = CubeColor.white;

  final preserved = [
    const MapEntry(CubeFace.u, 3),
    const MapEntry(CubeFace.u, 5),
    const MapEntry(CubeFace.u, 7),
  ];

  final moves = PiecePathSolver.findPreservingPath(
    startFace: CubeFace.f,
    startIndex: 7,
    targetFace: CubeFace.u,
    targetIndex: 1,
    preservedStickers: preserved,
  );

  if (moves == null) {
    _log.severe('FAILED: No path found.');
    return;
  }

  _log.info('Path found: ${moves.join(" ")}');

  var state = initialState;
  for (final move in moves) {
    state = state.applyMove(move);
  }

  // Check results
  bool success = true;
  if (state.u[1] != CubeColor.white) {
    _log.severe('FAILED: Target U1 is not white! Found: ${state.u[1]}');
    success = false;
  }

  if (state.u[3] != CubeColor.white) {
    _log.severe('FAILED: Preserved U3 is no longer white!');
    success = false;
  }
  if (state.u[5] != CubeColor.white) {
    _log.severe('FAILED: Preserved U5 is no longer white!');
    success = false;
  }
  if (state.u[7] != CubeColor.white) {
    _log.severe('FAILED: Preserved U7 is no longer white!');
    success = false;
  }

  if (success) {
    _log.info('PASSED: Cross scenario!');
  } else {
    _log.severe('FAILED: Cross scenario checks failed.');
  }

  _log.info('\nTesting corner preservation...');
  // Scenario: First Layer Corners
  // White cross and 3 corners solved on U.
  // 4th corner (white-red-blue) is at F8.
  // Goal: Move F8 to U2 without disturbing other pieces on U.

  final state2 = CubeState.solved();
  // Solved cross
  for (int i in [1, 3, 5, 7]) {
    state2.u[i] = CubeColor.white;
  }
  // 3 solved corners
  for (int i in [0, 6, 8]) {
    state2.u[i] = CubeColor.white;
  }
  // Target center
  state2.u[4] = CubeColor.white;

  // Scramble a bit to move the target corner piece to F8
  // (In a real cube, white-red-blue corner would start at U2)
  state2.f[8] = CubeColor.white;

  final preserved2 = [
    for (int i = 0; i < 9; i++)
      if (i != 2) MapEntry(CubeFace.u, i),
  ];

  final moves2 = PiecePathSolver.findPreservingPath(
    startFace: CubeFace.f,
    startIndex: 8,
    targetFace: CubeFace.u,
    targetIndex: 2,
    preservedStickers: preserved2,
  );

  if (moves2 == null) {
    _log.severe('FAILED: No path found for corners.');
  } else {
    _log.info('Path found: ${moves2.join(" ")}');
    var resultState = state2;
    for (final m in moves2) {
      resultState = resultState.applyMove(m);
    }

    bool cornerSuccess = true;
    if (resultState.u[2] != CubeColor.white) {
      _log.severe('FAILED: U2 is not white!');
      cornerSuccess = false;
    }
    for (int i = 0; i < 9; i++) {
      if (i == 2) continue;
      if (resultState.u[i] != CubeColor.white) {
        _log.severe('FAILED: Preserved U$i is no longer white!');
        cornerSuccess = false;
      }
    }

    if (cornerSuccess) {
      _log.info('PASSED: Corner scenario!');
    } else {
      _log.severe('FAILED: Corner checks failed.');
    }
  }
}
