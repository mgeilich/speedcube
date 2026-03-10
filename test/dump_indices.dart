// ignore_for_file: avoid_print

import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';

void main() {
  final s = CubeState.solved();
  print('Solved state indices:');
  _dump(s);

  print('\nRotating F:');
  _dump(s.applyMove(CubeMove.f));

  print('\nRotating R:');
  _dump(s.applyMove(CubeMove.r));

  print('\nRotating U:');
  _dump(s.applyMove(CubeMove.u));

  print('\nRotating D:');
  _dump(s.applyMove(CubeMove.d));
}

void _dump(CubeState s) {
  print('U: ${s.u}');
  print('D: ${s.d}');
  print('F: ${s.f}');
  print('B: ${s.b}');
  print('R: ${s.r}');
  print('L: ${s.l}');
}
