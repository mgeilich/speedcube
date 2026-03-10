import 'package:logging/logging.dart';
import 'package:speedcube_ar/utils/logging_config.dart';
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/kociemba_coordinates.dart';

void main() {
  initLogging();
  final log = Logger('CheckEoLogic');

  final moves = [
    CubeMove.f,
    CubeMove.r,
    CubeMove.u,
    CubeMove.rPrime,
    CubeMove.uPrime,
    CubeMove.fPrime
  ];

  var state = CubeState.solved();
  for (final m in moves) {
    state = state.applyMove(m);
  }

  final cube = KociembaCube.fromCubeState(state);
  log.info('EO after F R U R\' U\' F\': ${cube.eo}');

  // Edge order: uR, uF, uL, uB, ...
  if (cube.eo[0] == 1) log.info('UR is BAD');
  if (cube.eo[1] == 1) log.info('UF is BAD');
  if (cube.eo[2] == 1) log.info('UL is BAD');
  if (cube.eo[3] == 1) log.info('UB is BAD');
}
