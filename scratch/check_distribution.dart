import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/alg_library.dart';
import 'package:logging/logging.dart';

void main() {
  // Configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(record.message);
  });
  final logger = Logger('CheckDistribution');

  logger.info('--- OLL Yellow Distribution Check ---');
  
  for (var alg in AlgLibrary.oll) {
    var state = CubeState.yellowTopSolved();
    for (var move in alg.setupMoveList) {
      state = state.applyMove(move);
    }
    
    int top = state.u.where((c) => c == CubeColor.yellow).length;
    int side = 0;
    side += state.f.sublist(0, 3).where((c) => c == CubeColor.yellow).length;
    side += state.b.sublist(0, 3).where((c) => c == CubeColor.yellow).length;
    side += state.r.sublist(0, 3).where((c) => c == CubeColor.yellow).length;
    side += state.l.sublist(0, 3).where((c) => c == CubeColor.yellow).length;
    
    if (top + side != 9) {
      logger.warning('${alg.id}: $top top, $side side (Total: ${top+side})');
    }
  }
}
