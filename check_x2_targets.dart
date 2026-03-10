// ignore_for_file: avoid_print
import 'lib/solver/kociemba_coordinates.dart';

void main() {
  var cube = KociembaCube();
  print("Solved CP: ${cube.cp}");
  print("Solved EP: ${cube.ep}");

  cube.rotateX(2);
  print("\nAfter x2:");
  print("CP: ${cube.cp}");
  print("EP: ${cube.ep}");
  print("CO: ${cube.co}");
  print("EO: ${cube.eo}");
}
