import 'lib/models/cube_state.dart';
import 'lib/models/cube_move.dart';

void main() {
  var state = CubeState.solved();
  
  var moves5 = "Rw' U' R U' R' U2 Rw".split(' ').map((s) => CubeMove.parse(s)).whereType<CubeMove>().toList();
  var res5 = state.applyMoves(moves5);
  print('OLL 5 U: ${res5.u.map((c) => c.toString().split('.').last[0]).join('')}');
}
