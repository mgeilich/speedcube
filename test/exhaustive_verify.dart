// ignore_for_file: avoid_print

import 'package:speedcube_ar/solver/kociemba_tables.dart';
import 'package:speedcube_ar/solver/kociemba_coordinates.dart';

void main() async {
  print('Loading tables...');
  await KociembaTables.init();

  print('Verifying Twist Move Table...');
  int twistErrors = 0;
  for (int i = 0; i < KociembaTables.nTwist; i++) {
    for (int m = 0; m < 18; m++) {
      final face = KociembaCube.allFaces[m ~/ 3];
      final turns = (m % 3) + 1;

      final cube = KociembaCube();
      cube.twist = i;
      cube.applyMove(face, turns);

      final expected = cube.twist;
      final actual = KociembaTables.twistMove[i][m];

      if (expected != actual) {
        if (twistErrors < 5) {
          print('  ERROR: Twist $i move $m: expected $expected, got $actual');
        }
        twistErrors++;
      }
    }
  }

  if (twistErrors == 0) {
    print('  Twist Move Table OK!');
  } else {
    print('  Twist Move Table FAILED with $twistErrors errors.');
  }

  print('Verifying Flip Move Table...');
  int flipErrors = 0;
  for (int i = 0; i < KociembaTables.nFlip; i++) {
    for (int m = 0; m < 18; m++) {
      final face = KociembaCube.allFaces[m ~/ 3];
      final turns = (m % 3) + 1;

      final cube = KociembaCube();
      cube.flip = i;
      cube.applyMove(face, turns);

      final expected = cube.flip;
      final actual = KociembaTables.flipMove[i][m];

      if (expected != actual) {
        if (flipErrors < 5) {
          print('  ERROR: Flip $i move $m: expected $expected, got $actual');
        }
        flipErrors++;
      }
    }
  }

  if (flipErrors == 0) {
    print('  Flip Move Table OK!');
  } else {
    print('  Flip Move Table FAILED with $flipErrors errors.');
  }

  print('Verifying Slice Move Table...');
  int sliceErrors = 0;
  for (int i = 0; i < KociembaTables.nSlice; i++) {
    for (int m = 0; m < 18; m++) {
      final face = KociembaCube.allFaces[m ~/ 3];
      final turns = (m % 3) + 1;

      final cube = KociembaCube();
      cube.slice = i;
      cube.applyMove(face, turns);

      final expected = cube.slice;
      final actual = KociembaTables.sliceMove[i][m];

      if (expected != actual) {
        if (sliceErrors < 5) {
          print('  ERROR: Slice $i move $m: expected $expected, got $actual');
        }
        sliceErrors++;
      }
    }
  }

  if (sliceErrors == 0) {
    print('  Slice Move Table OK!');
  } else {
    print('  Slice Move Table FAILED with $sliceErrors errors.');
  }

  print('Verification complete.');
}
