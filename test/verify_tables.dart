// ignore_for_file: avoid_print

import 'package:speedcube_ar/solver/kociemba_tables.dart';
import 'package:speedcube_ar/solver/kociemba_coordinates.dart';
import 'package:speedcube_ar/models/cube_move.dart';

void main() async {
  print('Loading tables...');
  await KociembaTables.init();

  print('Twist Move Table (first 5):');
  for (int i = 0; i < 5; i++) {
    print('  [$i]: ${KociembaTables.twistMove[i].sublist(0, 6)}');
  }

  print('TwistSlice Pruning Table (first 20):');
  print('  ${KociembaTables.twistSlicePrun.sublist(0, 20)}');

  int tw = 388;
  int sl = 11;
  int idx1 = tw * KociembaTables.nSlice + sl;
  print(
      'Pruning for twist=$tw, slice=$sl: ${KociembaTables.twistSlicePrun[idx1]}');

  print('Twist moves for $tw:');
  print('  ${KociembaTables.twistMove[tw]}');

  final cube = KociembaCube();
  cube.twist = tw;
  cube.applyMove(CubeFace.u, 1);
  int nextTw = cube.twist;
  int tableTw = KociembaTables.twistMove[tw][0];
  print('Twist transition (U): state=$tw, cube=$nextTw, table=$tableTw');

  cube.twist = tw;
  cube.applyMove(CubeFace.l, 1);
  nextTw = cube.twist;
  tableTw = KociembaTables.twistMove[tw][6]; // L is index 6
  print('Twist transition (L): state=$tw, cube=$nextTw, table=$tableTw');

  if (nextTw != tableTw) {
    print(
        'CRITICAL FAILURE: Table move $tableTw does NOT match cube move $nextTw');
  } else {
    print('SUCCESS: Table move matches cube move.');
  }

  print('Verification complete.');
}
