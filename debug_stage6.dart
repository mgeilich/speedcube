// ignore_for_file: avoid_print
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/lbl_solver.dart';

void main() {
  final scrambleStr = "U' B D' R' L D R B' L' B R F' B' L' D' U' D' F U' R'";
  final moves = scrambleStr
      .split(' ')
      .map((s) => CubeMove.parse(s))
      .where((m) => m != null)
      .cast<CubeMove>()
      .toList();
  var s = CubeState.solved().applyMoves(moves);

  final whiteFace = CubeFace.u; // Simplified for debug of known scramble
  final p = LblSolver.perspectiveFor(whiteFace);

  final res = LblSolver.solve(s)!;

  print("Tracing stages...");
  String lastStage = "";
  Perspective currentP = p; // Start with white-on-top
  for (final step in res.steps) {
    if (step.stageName != lastStage) {
      lastStage = step.stageName;
      // We flip to p2 after White Cross
      if (lastStage == "First Layer") {
        currentP = LblSolver.perspectiveFlipped(p);
      }
      print("\n--- ENTERING STAGE: $lastStage ---");
      _inspect(s, lastStage, currentP);
    }
    // Update s and check state
    s = s.applyMoves(step.moves);
  }
  print("\n--- FINAL STATE ---");
  _inspect(s, "Final", currentP);
}

void _inspect(CubeState s, String tag, Perspective p) {
  final up = p.u;
  final sideIndex = (up == CubeFace.u) ? 1 : 7;
  final yellow = CubeColor.yellow;
  final sides = [p.f, p.r, p.b, p.l];

  int yEdgeCount = 0;
  for (int i in [1, 3, 5, 7]) {
    if (s.getFace(up)[i] == yellow) yEdgeCount++;
  }

  int sideMatchCount = 0;
  for (final f in sides) {
    if (s.getFace(f)[sideIndex] == s.getFace(f)[4]) sideMatchCount++;
  }

  print("  [$tag] Y-Edges on Top: $yEdgeCount, Sides match: $sideMatchCount");
}
