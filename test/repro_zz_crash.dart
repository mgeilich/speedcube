// ignore_for_file: avoid_print
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/zz_solver.dart';

void main() {
  // Scramble the cube (approx 20 moves)
  final scramble = "R U R' U' F R2 U' R' U' R U R' F' L U L' U' L' B L B'";
  print("Testing ZZ Solver with scramble: $scramble");
  
  final moves = scramble.split(' ').map((m) => CubeMove.parse(m)!).toList();
  var state = CubeState.solved().applyMoves(moves);
  
  final stopwatch = Stopwatch()..start();
  
  // Test ZZ Solver
  print("Running ZZ Solver...");
  final result = ZzSolver.solve(state);
  
  stopwatch.stop();
  
  if (result != null) {
    print("SUCCESS: Solution found in ${stopwatch.elapsedMilliseconds}ms");
    print("Move count: ${result.allMoves.length}");
    
    // Safety check: verify the solution
    var solvedState = state.applyMoves(result.allMoves);
    if (solvedState.isSolved) {
      print("VERIFIED: Cube is solved!");
    } else {
      print("FAILURE: solution does not solve the cube!");
    }
  } else {
    print("FAILURE: No solution found within budget.");
  }
}
