// ignore_for_file: avoid_print
import 'lib/models/cube_state.dart';
import 'lib/models/cube_move.dart';
import 'lib/solver/petrus_solver.dart';
import 'lib/solver/kociemba_coordinates.dart';

void main() async {
  print("=== Testing Petrus Solver Stage-by-Stage ===");

  // Scramble: D U' B2 D' R' B B2 L2 B2 D2 U2 L U2 R F U' B U' L R'
  final scramble = [
    CubeMove(CubeFace.d, 1), CubeMove(CubeFace.u, -1), CubeMove(CubeFace.b, 2),
    CubeMove(CubeFace.d, -1), CubeMove(CubeFace.r, -1), CubeMove(CubeFace.b, 1),
    CubeMove(CubeFace.b, 2), CubeMove(CubeFace.l, 2), CubeMove(CubeFace.b, 2),
    CubeMove(CubeFace.d, 2), CubeMove(CubeFace.u, 2), CubeMove(CubeFace.l, 1),
    CubeMove(CubeFace.u, 2), CubeMove(CubeFace.r, 1), CubeMove(CubeFace.f, 1),
    CubeMove(CubeFace.u, -1), CubeMove(CubeFace.b, 1), CubeMove(CubeFace.u, -1),
    CubeMove(CubeFace.l, 1), CubeMove(CubeFace.r, -1)
  ];
  final state = CubeState.solved().applyMoves(scramble);
  final currentCube = KociembaCube.fromCubeState(state);

  print("\n--- Stage 1: 2x2x2 Block ---");
  final s1 = PetrusSolver.solve2x2x2(currentCube);
  if (s1.isNotEmpty) {
    print("Moves: \${s1.map((m) => m.toString()).join(' ')}");
    for (final m in s1) {
      currentCube.applyMove(m.face, m.turns);
    }
    print("Stage 1: SUCCESS");
  } else {
    print("Stage 1: FAILED");
  }

  print("\n--- Stage 2: 2x2x3 Expansion ---");
  final s2 = PetrusSolver.solve2x2x3(currentCube);
  if (s2.isNotEmpty) {
    print("Moves: \${s2.map((m) => m.toString()).join(' ')}");
    for (final m in s2) {
      currentCube.applyMove(m.face, m.turns);
    }
    print("Stage 2: SUCCESS");
  } else {
    print("Stage 2: FAILED");
  }

  print("\n--- Stage 3: Edge Orientation ---");
  final s3 = PetrusSolver.solveEO(currentCube);
  if (s3.isNotEmpty) {
    print("Moves: \${s3.map((m) => m.toString()).join(' ')}");
    for (final m in s3) {
      currentCube.applyMove(m.face, m.turns);
    }
    print("Stage 3: SUCCESS");
  } else {
    print("Stage 3: FAILED");
  }

  print("\n--- Stage 4: Finish F2L ---");
  final s4 = PetrusSolver.solveF2L(currentCube);
  if (s4.isNotEmpty) {
    print("Moves: \${s4.map((m) => m.toString()).join(' ')}");
    for (final m in s4) {
      currentCube.applyMove(m.face, m.turns);
    }
    print("Stage 4: SUCCESS");
  } else {
    print("Stage 4: FAILED");
  }

  print("\n--- Stage 5: Last Layer ---");
  // solveLL now takes a CubeState. We need to convert our working KociembaCube or just apply all moves to the start state.
  final allMovesSoFar = [...s1, ...s2, ...s3, ...s4];
  final stateAfterF2L = state.applyMoves(allMovesSoFar);
  
  final s5 = await PetrusSolver.solveLL(stateAfterF2L);
  if (s5.isNotEmpty) {
    print("Moves: \${s5.map((m) => m.toString()).join(' ')}");
    print("Stage 5: SUCCESS");
  } else {
    // If it was already solved, it returns empty
    if (stateAfterF2L.isSolved) {
      print("Stage 5: ALREADY SOLVED");
    } else {
      print("Stage 5: FAILED");
    }
  }

  final finalState = stateAfterF2L.applyMoves(s5);
  if (finalState.isSolved) {
    print("\nFINAL RESULT: SOLVED!");
  } else {
    print("\nFINAL RESULT: FAILED");
  }
}
