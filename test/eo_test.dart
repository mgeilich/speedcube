import 'package:logging/logging.dart';
import 'package:speedcube_ar/utils/logging_config.dart';
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';

void main() {
  initLogging();
  final log = Logger('EoTest');

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

  log.info('--- Algorithm: F R U R\' U\' F\' ---');

  bool isWhite(CubeColor c) => c == CubeColor.white;

  log.info('U Face Edges (Standard Solved: all true):');
  log.info('UB (index 1): ${isWhite(state.u[1])}');
  log.info('UL (index 3): ${isWhite(state.u[3])}');
  log.info('UR (index 5): ${isWhite(state.u[5])}');
  log.info('UF (index 7): ${isWhite(state.u[7])}');
}
