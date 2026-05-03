import 'lib/models/cube_state.dart';
import 'lib/models/cube_move.dart';

void main() {
  var state = CubeState.solved();
  
  // Test wide Sune inverse
  var movesSune = "Rw U R' U R U2 Rw'".split(' ').map((s) => CubeMove.parse(s)).whereType<CubeMove>().toList();
  var resSune = state.applyMoves(movesSune);
  print('Wide Sune inverse U: ${resSune.u.map((c) => c.toString().split('.').last[0]).join('')}');
  
  // Test wide Anti-Sune inverse
  var movesAnti = "Rw U2 R' U' R U' Rw'".split(' ').map((s) => CubeMove.parse(s)).whereType<CubeMove>().toList();
  var resAnti = state.applyMoves(movesAnti);
  print('Wide Anti-Sune inverse U: ${resAnti.u.map((c) => c.toString().split('.').last[0]).join('')}');
}
