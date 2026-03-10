// ignore_for_file: avoid_print
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/kociemba_coordinates.dart';

int countUserBad(KociembaCube cube) {
  int bad = 0;
  for (int i = 0; i < 12; i++) {
    final piece = cube.ep[i];
    final ori = cube.eo[i];
    if (piece < 8) {
      if (i >= 8 || ori == 1) bad++;
    }
    if (piece >= 8) {
      if (i < 8 || ori == 1) bad++;
    }
  }
  return bad;
}

void main() {
  final centers = {
    CubeFace.u: CubeColor.white,
    CubeFace.d: CubeColor.yellow,
    CubeFace.f: CubeColor.green,
    CubeFace.b: CubeColor.blue,
    CubeFace.r: CubeColor.orange,
    CubeFace.l: CubeColor.red,
  };

  KociembaCube cube = KociembaCube(centers);

  void applyBlock(KociembaCube c, List<CubeMove> setup) {
    for (var m in setup) {
      c.applyMove(m.face, m.turns);
    }
    // Algorithm F U R U' R' F'
    c.applyMove(CubeFace.f, 1);
    c.applyMove(CubeFace.u, 1);
    c.applyMove(CubeFace.r, 1);
    c.applyMove(CubeFace.u, -1);
    c.applyMove(CubeFace.r, -1);
    c.applyMove(CubeFace.f, -1);
    for (var m in setup.reversed) {
      c.applyMove(m.face, -m.turns);
    }
  }

  // Generate scramble S by 4 blocks
  applyBlock(cube, []);
  applyBlock(cube, [CubeMove.u]);
  applyBlock(cube, [CubeMove.r2, CubeMove.l2]);
  applyBlock(cube, [CubeMove.r2, CubeMove.l2, CubeMove.u]);

  print("Bad edges after scramble: ${countUserBad(cube)}");

  // Now solve S by applying the SAME 4 blocks?
  // No, applying the same block skips orientation?
  // Wait. Flip^2 in orientation is...
  // My test_multi_eo.dart showed 3 applications = Identity (orientation 0).
  // So 1 application (scramble) + 2 applications (solve) = 3 applications = Identity!
  // So to solve it, we must apply each block TWICE.
  // 4 blocks * 2 flips each = 8 flips.
  // User wants 4 flips (4 pairs).

  // Wait! If I just apply the ALGO once in a block, it flips them.
  // If they are bad, they become good.
  // So I only need to apply each block ONCE to solve it!

  // Let's verify: State S + Block 1 -> State S'
  KociembaCube s = cube.clone();
  print("Pre-solve Bad count: ${countUserBad(s)}");
  applyBlock(s, [CubeMove.r2, CubeMove.l2, CubeMove.u]);
  print("After block 1: ${countUserBad(s)}");
  applyBlock(s, [CubeMove.r2, CubeMove.l2]);
  print("After block 2: ${countUserBad(s)}");
  applyBlock(s, [CubeMove.u]);
  print("After block 3: ${countUserBad(s)}");
  applyBlock(s, []);
  print("After block 4: ${countUserBad(s)}");
}

extension on KociembaCube {
  KociembaCube clone() {
    final c = KociembaCube(centers);
    for (int i = 0; i < 8; i++) {
      c.cp[i] = cp[i];
      c.co[i] = co[i];
    }
    for (int i = 0; i < 12; i++) {
      c.ep[i] = ep[i];
      c.eo[i] = eo[i];
    }
    return c;
  }
}
