import 'lib/models/cube_state.dart';
import 'lib/models/cube_move.dart';

void main() {
  var state = CubeState.solved();
  
  // T pattern algorithm: r U R' U' r' F R F'
  // Inverse: F R' F' r U R U' r'
  var moves = "F R' F' r U R U' r'".split(' ').map((s) => CubeMove.parse(s)).whereType<CubeMove>().toList();
  var res = state.applyMoves(moves);
  
  print('U: ${res.u.map((c) => c.toString().split('.').last[0]).join('')}');
  print('L: ${res.l.map((c) => c.toString().split('.').last[0]).join('')}');
  print('F: ${res.f.map((c) => c.toString().split('.').last[0]).join('')}');
  print('R: ${res.r.map((c) => c.toString().split('.').last[0]).join('')}');
  print('B: ${res.b.map((c) => c.toString().split('.').last[0]).join('')}');
}
