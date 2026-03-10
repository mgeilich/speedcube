import 'package:logging/logging.dart';
import 'package:speedcube_ar/utils/logging_config.dart';
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/kociemba_coordinates.dart';

void main() {
  initLogging();
  final log = Logger('VerifyEoFinal');

  final alg = [
    CubeMove.f,
    CubeMove.r,
    CubeMove.u,
    CubeMove.rPrime,
    CubeMove.uPrime,
    CubeMove.fPrime
  ];

  var state = CubeState.solved();
  for (final m in alg) {
    state = state.applyMove(m);
  }

  final cube = KociembaCube.fromCubeState(state);
  log.info('Final EO: ${cube.eo}');

  // Edge order: UR, UF, UL, UB, DR, DF, DL, DB, FR, FL, BR, BL
  // P1 defines UR, UF, UL, UB (indices 0,1,2,3) as bad if they have 1.
  for (int i = 0; i < 4; i++) {
    if (cube.eo[i] == 1) {
      log.info('Edge $i is BAD');
    }
  }
}
