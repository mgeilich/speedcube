// ignore_for_file: avoid_print

import 'package:speedcube_ar/solver/kociemba_tables.dart';

void main() async {
  print('Loading tables...');
  await KociembaTables.init();

  print('Auditing twistSlicePrun...');
  int twistZeros = 0;
  for (int i = 0; i < KociembaTables.twistSlicePrun.length; i++) {
    if (KociembaTables.twistSlicePrun[i] == 0) {
      if (twistZeros < 10) {
        print('  Zero at index $i (twist=${i ~/ 495}, slice=${i % 495})');
      }
      twistZeros++;
    }
  }
  print('  Total zeros in twistSlicePrun: $twistZeros');

  print('Auditing flipSlicePrun...');
  int flipZeros = 0;
  for (int i = 0; i < KociembaTables.flipSlicePrun.length; i++) {
    if (KociembaTables.flipSlicePrun[i] == 0) {
      if (flipZeros < 10) {
        print('  Zero at index $i (flip=${i ~/ 495}, slice=${i % 495})');
      }
      flipZeros++;
    }
  }
  print('  Total zeros in flipSlicePrun: $flipZeros');

  print('Auditing cpUspPrun...');
  int cpZeros = 0;
  for (int i = 0; i < KociembaTables.cpUspPrun.length; i++) {
    if (KociembaTables.cpUspPrun[i] == 0) {
      if (cpZeros < 10) {
        print('  Zero at index $i');
      }
      cpZeros++;
    }
  }
  print('  Total zeros in cpUspPrun: $cpZeros');

  print('Verification complete.');
}
