// ignore_for_file: avoid_print
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/kociemba_coordinates.dart';

void main() {
  final centers = {
    CubeFace.u: CubeColor.white,
    CubeFace.d: CubeColor.yellow,
    CubeFace.f: CubeColor.green,
    CubeFace.b: CubeColor.blue,
    CubeFace.r: CubeColor.orange,
    CubeFace.l: CubeColor.red,
  };
  KociembaCube c = KociembaCube(centers);
  // Set 1 and 3 to BAD
  c.eo[1] = 1;
  c.eo[3] = 1;

  void applyAlgo(KociembaCube k) {
    k.applyMove(CubeFace.f, 1);
    k.applyMove(CubeFace.u, 1);
    k.applyMove(CubeFace.r, 1);
    k.applyMove(CubeFace.u, -1);
    k.applyMove(CubeFace.r, -1);
    k.applyMove(CubeFace.f, -1);
  }

  print("Initial EO: ${c.eo}");
  applyAlgo(c);
  applyAlgo(c);
  applyAlgo(c);
  print("After 3 EO: ${c.eo}");
  print("Final Permutation: ${c.ep}");
}
