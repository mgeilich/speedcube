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

  void applyAlgo(KociembaCube k) {
    k.applyMove(CubeFace.f, 1);
    k.applyMove(CubeFace.r, 1);
    k.applyMove(CubeFace.u, 1);
    k.applyMove(CubeFace.r, -1);
    k.applyMove(CubeFace.u, -1);
    k.applyMove(CubeFace.f, -1);
  }

  applyAlgo(c);
  print("Final ep: ${c.ep}");
  print("Final eo: ${c.eo}");
}
