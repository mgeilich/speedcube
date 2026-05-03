import 'lib/models/cube_state.dart';
import 'lib/models/cube_move.dart';
import 'lib/models/alg_library.dart';

void main() {
  var state = CubeState.solved();
  
  for (var case_ in AlgLibrary.pllCases) {
    var moves = case_.setupMoveList;
    var res = state.applyMoves(moves);
    
    // Check if U face is all yellow? No, solved state has white on top!
    // Wait, CubeState.solved() has white on top.
    // Let's check if all u stickers are white.
    bool allWhite = res.u.every((c) => c.toString().split('.').last == 'white');
    if (!allWhite) {
      print('${case_.id} (${case_.name}) has unoriented top layer: ${res.u.map((c) => c.toString().split('.').last[0]).join('')}');
    }
  }
}
