// ignore_for_file: avoid_print
import 'lib/models/cube_state.dart';
import 'lib/models/cube_move.dart';
import 'lib/solver/kociemba_coordinates.dart';

void main() {
  final faces = [
    CubeFace.u,
    CubeFace.d,
    CubeFace.l,
    CubeFace.r,
    CubeFace.f,
    CubeFace.b
  ];

  for (final f in faces) {
    print("\n--- Cycle for $f ---");
    var state = CubeState.solved();
    state = state.applyMove(CubeMove(f, 1));
    var cube = KociembaCube.fromCubeState(state);

    // Check which corners moved
    var movedCorners = <int>[];
    for (int i = 0; i < 8; i++) {
      if (cube.cp[i] != i || cube.co[i] != 0) {
        movedCorners.add(i);
      }
    }
    print("Moved corners spots: $movedCorners");
    // Find the cycle
    // Note: cube.cp[spot] = physical piece index originally at some spot.
    // Solving for spot s: cube.cp[s] is the piece now at s.
    // So the piece originally at spot X moved to spot Y.
    // Piece i was at spot i. Now piece i is at spot s where cube.cp[s] == i.

    var cpCycle = List.filled(8, -1);
    for (int s = 0; s < 8; s++) {
      int piece = cube.cp[s];
      cpCycle[piece] = s; // Piece originally at 'piece' is now at 's'
    }

    // Trace 4-cycle
    if (movedCorners.length == 4) {
      int start = movedCorners[0];
      int c1 = start;
      int c2 = cpCycle[c1];
      int c3 = cpCycle[c2];
      int c4 = cpCycle[c3];
      print("CP Cycle: [$c1, $c2, $c3, $c4]");
      print(
          "CO Changes: [${cube.co[c1]}, ${cube.co[c2]}, ${cube.co[c3]}, ${cube.co[c4]}]");
    }

    // Edges
    var movedEdges = <int>[];
    for (int i = 0; i < 12; i++) {
      if (cube.ep[i] != i || cube.eo[i] != 0) {
        movedEdges.add(i);
      }
    }
    print("Moved edges spots: $movedEdges");
    var epCycle = List.filled(12, -1);
    for (int s = 0; s < 12; s++) {
      int piece = cube.ep[s];
      epCycle[piece] = s;
    }
    if (movedEdges.length == 4) {
      int start = movedEdges[0];
      int e1 = start;
      int e2 = epCycle[e1];
      int e3 = epCycle[e2];
      int e4 = epCycle[e3];
      print("EP Cycle: [$e1, $e2, $e3, $e4]");
      print(
          "EO Changes: [${cube.eo[e1]}, ${cube.eo[e2]}, ${cube.eo[e3]}, ${cube.eo[e4]}]");
    }
  }
}
