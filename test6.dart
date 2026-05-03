import 'lib/models/cube_state.dart';
import 'lib/models/cube_move.dart';

void main() {
  var state = CubeState.solved();
  
  // Test OLL 5: l' U2 L U L' U l
  var moves5 = "Lw' U2 L U L' U Lw".split(' ').map((s) => CubeMove.parse(s)).whereType<CubeMove>().toList();
  var res5 = state.applyMoves(moves5);
  print('OLL 5 U: ${res5.u.map((c) => c.toString().split('.').last[0]).join('')}');
  
  // Test OLL 6: r U2 R' U' R U' r'
  var moves6 = "Rw U2 R' U' R U' Rw'".split(' ').map((s) => CubeMove.parse(s)).whereType<CubeMove>().toList();
  var res6 = state.applyMoves(moves6);
  print('OLL 6 U: ${res6.u.map((c) => c.toString().split('.').last[0]).join('')}');
}
