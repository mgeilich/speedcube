// ignore_for_file: avoid_print

import 'package:speedcube_ar/models/cube_state.dart';

void main() {
  final state = CubeState.solved();
  // U:white(0), D:yellow(1), F:green(2), B:blue(3), R:red(4), L:orange(5)

  print('Testing rotateY (CW from top)...');
  var ry = state.rotateY();
  // F -> L, L -> B, B -> R, R -> F
  // ry.f should be old R (Red)
  // ry.l should be old F (Green)
  if (ry.f[4] == CubeColor.red && ry.l[4] == CubeColor.green) {
    print('SUCCESS: rotateY centers correct.');
  } else {
    print('FAILURE: rotateY centers incorrect. F:${ry.f[4]}, L:${ry.l[4]}');
  }

  print('Testing rotateX (CW from right)...');
  var rx = state.rotateX();
  // F -> U, U -> B, B -> D, D -> F
  // rx.u should be old F (Green)
  // rx.f should be old D (Yellow)
  if (rx.u[4] == CubeColor.green && rx.f[4] == CubeColor.yellow) {
    print('SUCCESS: rotateX centers correct.');
  } else {
    print('FAILURE: rotateX centers incorrect. U:${rx.u[4]}, F:${rx.f[4]}');
  }

  print('Testing rotateZ (CW from front)...');
  var rz = state.rotateZ();
  // U -> R, R -> D, D -> L, L -> U
  // rz.r should be old U (White)
  // rz.u should be old L (Orange)
  if (rz.r[4] == CubeColor.white && rz.u[4] == CubeColor.orange) {
    print('SUCCESS: rotateZ centers correct.');
  } else {
    print('FAILURE: rotateZ centers incorrect. R:${rz.r[4]}, U:${rz.u[4]}');
  }

  // Verify that 4 turns return to solved
  var y4 = state.rotateY().rotateY().rotateY().rotateY();
  if (y4.toString() == state.toString()) {
    print('SUCCESS: rotateY * 4 is identity.');
  } else {
    print('FAILURE: rotateY * 4 is NOT identity.');
  }
}
