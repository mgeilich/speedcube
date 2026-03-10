import 'package:logging/logging.dart';
import 'lib/utils/logging_config.dart';
import 'lib/models/cube_state.dart';
import 'lib/models/cube_move.dart';
import 'lib/solver/kociemba_coordinates.dart';

void main() {
  initLogging();
  final log = Logger('TestMultiEo');

  final centers = {
    CubeFace.u: CubeColor.white,
    CubeFace.d: CubeColor.yellow,
    CubeFace.f: CubeColor.green,
    CubeFace.b: CubeColor.blue,
    CubeFace.r: CubeColor.orange,
    CubeFace.l: CubeColor.red,
  };
  KociembaCube c = KociembaCube(centers);

  void applyAlgo(KociembaCube k) {
    k.applyMove(CubeFace.f, 1);
    k.applyMove(CubeFace.u, 1);
    k.applyMove(CubeFace.r, 1);
    k.applyMove(CubeFace.u, -1);
    k.applyMove(CubeFace.r, -1);
    k.applyMove(CubeFace.f, -1);
  }

  log.info("Initial EO: ${c.eo}");
  applyAlgo(c);
  log.info("After 1 EO: ${c.eo}");
  applyAlgo(c);
  log.info("After 2 EO: ${c.eo}");
  applyAlgo(c);
  log.info("After 3 EO: ${c.eo}");
  applyAlgo(c);
  log.info("After 4 EO: ${c.eo}");
}
