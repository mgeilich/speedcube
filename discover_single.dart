// ignore_for_file: avoid_print
import 'lib/models/cube_state.dart';
import 'lib/models/cube_move.dart';
import 'lib/solver/kociemba_coordinates.dart';

void main(List<String> args) {
  if (args.isEmpty) return;
  final f = CubeFace.values
      .firstWhere((e) => e.toString().split('.').last == args[0]);

  print("\n--- Cycle for $f ---");
  var state = CubeState.solved();
  state = state.applyMove(CubeMove(f, 1));
  var cube = KociembaCube.fromCubeState(state);

  // Check which corners moved
  var cpCycle = List.filled(8, -1);
  for (int s = 0; s < 8; s++) {
    int piece = cube.cp[s];
    cpCycle[piece] = s; // Piece originally at 'piece' is now at 's'
  }

  var movedCorners = <int>[];
  for (int i = 0; i < 8; i++) {
    if (cpCycle[i] != i || cube.co[cpCycle[i]] != 0) movedCorners.add(i);
  }

  if (movedCorners.length == 4) {
    int c1 = movedCorners[0];
    int c2 = cpCycle[c1];
    int c3 = cpCycle[c2];
    int c4 = cpCycle[c3];
    print("CP Cycle: [$c1, $c2, $c3, $c4]");
    print(
        "CO Changes at those spots: [${cube.co[c1]}, ${cube.co[c2]}, ${cube.co[c3]}, ${cube.co[c4]}]");
  }

  // Edges
  var epCycle = List.filled(12, -1);
  for (int s = 0; s < 12; s++) {
    int piece = cube.ep[s];
    epCycle[piece] = s;
  }
  var movedEdges = <int>[];
  for (int i = 0; i < 12; i++) {
    if (epCycle[i] != i || cube.eo[epCycle[i]] != 0) movedEdges.add(i);
  }

  if (movedEdges.length == 4) {
    int e1 = movedEdges[0];
    int e2 = epCycle[e1];
    int e3 = epCycle[e2];
    int e4 = epCycle[e3];
    print("EP Cycle: [$e1, $e2, $e3, $e4]");
    print(
        "EO Changes at those spots: [${cube.eo[e1]}, ${cube.eo[e2]}, ${cube.eo[e3]}, ${cube.eo[e4]}]");
  }
}
