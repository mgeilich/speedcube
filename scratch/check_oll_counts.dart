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
  final logger = Logger('CheckOLLCounts');

  logger.info('--- OLL Sticker Count Check ---');
  for (var alg in AlgLibrary.oll) {
    var state = CubeState.yellowTopSolved();
    // Setup the case
    for (var move in alg.setupMoveList) {
      state = state.applyMove(move);
    }
    
    // Count yellow on top
    int count = state.u.where((c) => c == CubeColor.yellow).length;
    
    // Also apply the algorithm and see if it solves it
    var solved = state;
    for (var move in alg.algorithmMoves) {
      solved = solved.applyMove(move);
    }
    int solvedCount = solved.u.where((c) => c == CubeColor.yellow).length;
    
    if (solvedCount != 9) {
      logger.severe('FAILED: ${alg.id} (${alg.name}) - Top stickers after alg: $solvedCount (Initial case stickers: $count)');
    } else {
      // If solved, print the initial count just for reference
      if (count == 8 || count == 7) {
         logger.info('UNUSUAL: ${alg.id} (${alg.name}) - Initial top stickers: $count (Solved after alg)');
      }
    }
  }
}
