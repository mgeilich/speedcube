import 'lib/models/cube_state.dart';
import 'lib/models/cube_move.dart';

void main() {
  var moves = "F R' F' Rw U R U' Rw'".split(' ').map((s) => CubeMove.parse(s)).whereType<CubeMove>().toList();
  var state = CubeState.solved().applyMoves(moves);
  print('U: ${state.u.map((c) => c.toString().split('.').last[0]).join('')}');
  print('L: ${state.l.map((c) => c.toString().split('.').last[0]).join('')}');
  print('R: ${state.r.map((c) => c.toString().split('.').last[0]).join('')}');
  print('Moves parsed: ${moves.join(' ')}');
}
