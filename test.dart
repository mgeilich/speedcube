import 'lib/models/cube_state.dart';
import 'lib/models/cube_move.dart';

void printCube(CubeState state) {
  print('U: ${state.u.map((c) => c.toString().split('.').last[0]).join('')}');
  print('L: ${state.l.map((c) => c.toString().split('.').last[0]).join('')}');
  print('F: ${state.f.map((c) => c.toString().split('.').last[0]).join('')}');
  print('R: ${state.r.map((c) => c.toString().split('.').last[0]).join('')}');
  print('B: ${state.b.map((c) => c.toString().split('.').last[0]).join('')}');
}

void main() {
  var state = CubeState.solved();
  
  // OLL 24 setup
  var moves24 = "R U R' U R U2 R' U2 R U2 R' U' R U' R'".trim().split(RegExp(r'\s+')).map((s) => CubeMove.parse(s)).whereType<CubeMove>().toList();
  var state24 = state.applyMoves(moves24);
  print('OLL 24:');
  printCube(state24);
  
  // OLL 25 setup
  var moves25 = "B' R' F R B R' F' R".trim().split(RegExp(r'\s+')).map((s) => CubeMove.parse(s)).whereType<CubeMove>().toList();
  var state25 = state.applyMoves(moves25);
  print('OLL 25:');
  printCube(state25);
}
