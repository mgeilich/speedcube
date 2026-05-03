import 'lib/models/cube_state.dart';
import 'lib/models/cube_move.dart';

void main() {
  var state = CubeState.solved();
  
  // Test R U2 R' U' R U' R2 U2 R U R' U R
  var algo = "R U2 R' U' R U' R2 U2 R U R' U R";
  // Inverse: R' U' R U' R' U2 R2 U R' U R U2 R'
  var moves = "R' U' R U' R' U2 R2 U R' U R U2 R'".split(' ').map((s) => CubeMove.parse(s)).whereType<CubeMove>().toList();
  var res = state.applyMoves(moves);
  
  print('U: ${res.u.map((c) => c.toString().split('.').last[0]).join('')}');
  print('L: ${res.l.map((c) => c.toString().split('.').last[0]).join('')}');
  print('F: ${res.f.map((c) => c.toString().split('.').last[0]).join('')}');
  print('R: ${res.r.map((c) => c.toString().split('.').last[0]).join('')}');
  print('B: ${res.b.map((c) => c.toString().split('.').last[0]).join('')}');
}
