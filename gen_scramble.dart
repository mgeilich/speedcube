// ignore_for_file: avoid_print
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/kociemba_coordinates.dart';
import 'dart:math';

int countUserBad(KociembaCube cube) {
  int bad = 0;
  for (int i = 0; i < 12; i++) {
    final piece = cube.ep[i];
    final ori = cube.eo[i];
    if (piece < 8) {
      // T/B pieces
      if (i >= 8 || ori == 1) bad++;
    } else {
      // Middle pieces
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

  final pool = <List<CubeMove>>[
    [],
    [CubeMove.u],
    [CubeMove.uPrime],
    [CubeMove.u2],
    [CubeMove.d],
    [CubeMove.dPrime],
    [CubeMove.d2],
    [CubeMove.r],
    [CubeMove.rPrime],
    [CubeMove.r2],
    [CubeMove.l],
    [CubeMove.lPrime],
    [CubeMove.l2],
    [CubeMove.r2, CubeMove.u],
    [CubeMove.r2, CubeMove.uPrime],
  ];

  final algo = [
    CubeMove.f,
    CubeMove.u,
    CubeMove.r,
    CubeMove.uPrime,
    CubeMove.rPrime,
    CubeMove.fPrime
  ];

  final random = Random();

  for (int trial = 0; trial < 1000; trial++) {
    KociembaCube cube = KociembaCube(centers);
    List<List<CubeMove>> blocks = [];

    for (int i = 0; i < 4; i++) {
      var setup = pool[random.nextInt(pool.length)];
      blocks.add(setup);

      // Apply block: Setup -> Flip -> Unsetup
      for (var m in setup) {
        cube.applyMove(m.face, m.turns);
      }
      // Apply algo
      cube.applyMove(CubeFace.f, 1);
      cube.applyMove(CubeFace.u, 1);
      cube.applyMove(CubeFace.r, 1);
      cube.applyMove(CubeFace.u, -1);
      cube.applyMove(CubeFace.r, -1);
      cube.applyMove(CubeFace.f, -1);
      for (var m in setup.reversed) {
        cube.applyMove(m.face, -m.turns);
      }
    }

    if (countUserBad(cube) >= 6) {
      // We want a decent number of bad edges
      print("Scramble Found!");
      print("Bad count: ${countUserBad(cube)}");
      print("Blocks (to be applied in reverse to solve):");
      for (int i = 3; i >= 0; i--) {
        print("Solve block ${4 - i}: ${blocks[i]}");
      }

      // Print the moves to generate this state
      // It's the same sequence of blocks!
      List<CubeMove> scrambleMoves = [];
      for (var b in blocks) {
        scrambleMoves.addAll(b);
        scrambleMoves.addAll(algo);
        scrambleMoves.addAll(b.reversed.map((m) => m.inverse));
      }
      print("Scramble moves: $scrambleMoves");
      return;
    }
  }
}
