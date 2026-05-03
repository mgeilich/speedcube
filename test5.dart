import 'lib/models/cube_state.dart';
import 'lib/models/cube_move.dart';

void main() {
  var state = CubeState.solved();
  
  // Test OLL 5 setup (inverse of L' U2 L U L' U L)
  // Inverse: L' U' L U' L' U2 L
  var moves5 = "L' U' L U' L' U2 L".split(' ').map((s) => CubeMove.parse(s)).whereType<CubeMove>().toList();
  var res5 = state.applyMoves(moves5);
  
  print('OLL 5:');
  print('U: ${res5.u.map((c) => c.toString().split('.').last[0]).join('')}');
  
  // Test OLL 6 standard: r U2 R' U' R U' r'
  // Inverse: r U R' U R U2 r'
  var moves6 = "Rw U R' U R U2 Rw'".split(' ').map((s) => CubeMove.parse(s)).whereType<CubeMove>().toList();
  var res6 = state.applyMoves(moves6);
  
  print('OLL 6:');
  print('U: ${res6.u.map((c) => c.toString().split('.').last[0]).join('')}');
}
