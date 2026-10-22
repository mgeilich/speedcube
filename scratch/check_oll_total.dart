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
  final logger = Logger('CheckOLLTotal');

  logger.info('--- OLL Total Yellow Check (Top + Sides) ---');
  for (var alg in AlgLibrary.oll) {
    var state = CubeState.yellowTopSolved();
    for (var move in alg.setupMoveList) {
      state = state.applyMove(move);
    }
    
    int top = state.u.where((c) => c == CubeColor.yellow).length;
    int f = state.f.sublist(0, 3).where((c) => c == CubeColor.yellow).length;
    int b = state.b.sublist(0, 3).where((c) => c == CubeColor.yellow).length;
    int r = state.r.sublist(0, 3).where((c) => c == CubeColor.yellow).length;
    int l = state.l.sublist(0, 3).where((c) => c == CubeColor.yellow).length;
    
    int total = top + f + b + r + l;
    if (total != 9) {
      logger.warning('FAILED: ${alg.id} - Total yellow: $total (Top: $top, F: $f, B: $b, R: $r, L: $l)');
    }
  }
}
