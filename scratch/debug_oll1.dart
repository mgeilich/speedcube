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
  final logger = Logger('DebugOLL1');

  final alg = AlgLibrary.oll.firstWhere((c) => c.id == 'oll1');
  var state = CubeState.yellowTopSolved();
  for (var move in alg.setupMoveList) {
    state = state.applyMove(move);
  }
  
  logger.info('--- OLL 1 Diagram ---');
  for (int i = 0; i < 3; i++) {
    final row = state.u.sublist(i * 3, i * 3 + 3).map((c) => c == CubeColor.yellow ? 'Y' : '.').join(' ');
    logger.info(row);
  }
  
  int count = state.u.where((c) => c == CubeColor.yellow).length;
  logger.info('Total yellow: $count');
}
