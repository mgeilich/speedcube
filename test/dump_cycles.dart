// ignore_for_file: avoid_print

import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/kociemba_coordinates.dart';

void main() {
  final faces = [
    CubeFace.u,
    CubeFace.d,
    CubeFace.l,
    CubeFace.r,
    CubeFace.f,
    CubeFace.b
  ];

  print('// Optimized Transitions (Generated)');
  for (final face in faces) {
    print('  case CubeFace.${face.name}:');
    final cube = KociembaCube();
    cube.applyMove(face, 1);

    // Debug physical rotation
    if (face == CubeFace.u) {
      final state = cube.toCubeState();
      print(
          '    // physical U stickers: ${state.u.map((c) => c.name[0].toUpperCase()).toList().join()}');
    }

    // Find corner cycles
    final cVisited = <int>{};
    for (int i = 0; i < 8; i++) {
      if (cVisited.contains(i)) continue;
      final cycle = <int>[];
      int curr = i;
      while (!cVisited.contains(curr)) {
        cVisited.add(curr);
        cycle.add(curr);
        for (int j = 0; j < 8; j++) {
          if (cube.cp[j] == curr) {
            curr = j;
            break;
          }
        }
      }
      if (cycle.length > 1) {
        final oChange = <int>[];
        for (final spot in cycle) {
          oChange.add(cube.co[spot]);
        }
        print('    _cycle${cycle.length}(cp, $cycle, co, $oChange, 3);');
      }
    }

    // Find edge cycles
    final eVisited = <int>{};
    for (int i = 0; i < 12; i++) {
      if (eVisited.contains(i)) continue;
      final cycle = <int>[];
      int curr = i;
      while (!eVisited.contains(curr)) {
        eVisited.add(curr);
        cycle.add(curr);
        for (int j = 0; j < 12; j++) {
          if (cube.ep[j] == curr) {
            curr = j;
            break;
          }
        }
      }
      if (cycle.length > 1) {
        final eoChange = <int>[];
        for (final spot in cycle) {
          eoChange.add(cube.eo[spot]);
        }
        print('    _cycle${cycle.length}(ep, $cycle, eo, $eoChange, 2);');
      }
    }
    print('    break;');
  }
}
