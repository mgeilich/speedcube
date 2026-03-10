// ignore_for_file: avoid_print
import 'lib/solver/kociemba_coordinates.dart';

void main() {
  var ref = KociembaCube()..rotateX(2);
  print("REF CP: ${ref.cp}");
  print("REF CO: ${ref.co}");
  print("REF EP: ${ref.ep}");
  print("REF EO: ${ref.eo}");
}
