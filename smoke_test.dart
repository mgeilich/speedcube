// ignore_for_file: avoid_print
import 'lib/solver/kociemba_coordinates.dart';
import 'lib/models/cube_move.dart';

void main() {
  print("Initializing KociembaCube...");
  var cube = KociembaCube();
  print("KociembaCube initialized.");

  print("Applying move U...");
  cube.applyMove(CubeFace.u, 1);
  print("Move U applied.");

  print("CP: ${cube.cp}");
  print("Smoke test complete.");
}
