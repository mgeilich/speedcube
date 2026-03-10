import 'package:logging/logging.dart';
import 'lib/utils/logging_config.dart';
import 'lib/models/cube_state.dart';
import 'lib/models/cube_move.dart';
import 'lib/solver/kociemba_coordinates.dart';

void main() {
  initLogging();
  final log = Logger('VerifyScramble');

  CubeState s = CubeState.solved()
      .applyMoves([CubeMove.f, CubeMove.b, CubeMove.r, CubeMove.l]);
  KociembaCube cube = KociembaCube.fromCubeState(s);
  log.info("Bad count: ${cube.badEdgeCount}");
  log.info("Bad EO: ${cube.eo}");

  List<String> badEdges = [];
  for (int i = 0; i < 12; i++) {
    if (cube.eo[i] != 0) {
      badEdges.add(Edge.values[i].toString().split('.').last);
    }
  }
  log.info("Bad edges by name: $badEdges");
}
