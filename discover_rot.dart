// ignore_for_file: avoid_print
import 'lib/models/cube_state.dart';
import 'lib/solver/kociemba_coordinates.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    return;
  }
  final mode = args[0]; // 'x' or 'y'

  print("\n--- Cycle for Rotation $mode ---");
  var state = CubeState.solved();
  if (mode == 'x') {
    state = state.rotateX();
  } else if (mode == 'y') {
    state = state.rotateY();
  } else if (mode == 'z') {
    state = state.rotateZ();
  }

  var cube = KociembaCube.fromCubeState(state);

  // Corners
  var cpCycle = List.filled(8, -1);
  for (int s = 0; s < 8; s++) {
    int piece = cube.cp[s];
    cpCycle[piece] = s;
  }

  // Rotations move ALL pieces (except maybe centers)
  // Let's find all cycles.
  var visited = List.filled(8, false);
  for (int i = 0; i < 8; i++) {
    if (visited[i]) continue;
    var cycle = <int>[];
    int curr = i;
    while (!visited[curr]) {
      visited[curr] = true;
      cycle.add(curr);
      curr = cpCycle[curr];
    }
    if (cycle.length > 1) {
      print("CP Cycle: $cycle");
      print(
          "CO Changes at these spots: ${cycle.map((s) => cube.co[s]).toList()}");
    }
  }

  // Edges
  var epCycle = List.filled(12, -1);
  for (int s = 0; s < 12; s++) {
    int piece = cube.ep[s];
    epCycle[piece] = s;
  }
  var visitedE = List.filled(12, false);
  for (int i = 0; i < 12; i++) {
    if (visitedE[i]) continue;
    var cycle = <int>[];
    int curr = i;
    while (!visitedE[curr]) {
      visitedE[curr] = true;
      cycle.add(curr);
      curr = epCycle[curr];
    }
    if (cycle.length > 1) {
      print("EP Cycle: $cycle");
      print(
          "EO Changes at those spots: ${cycle.map((s) => cube.eo[s]).toList()}");
    }
  }
}
