import '../models/cube_state.dart';
import '../models/cube_move.dart';
import 'kociemba_search.dart';

/// Puzzle cube solver.
///
/// Currently uses the Kociemba two-phase algorithm for optimal solutions.
/// Future premium features may include alternative solving methods,
/// visualization, and learning modes.
class BeginnerSolver {
  /// Solves the cube using the Kociemba algorithm.
  /// Returns an optimal solution (typically 18-22 moves).
  Future<List<CubeMove>> solve(CubeState initialState) async {
    final result = await KociembaSolver.solve(initialState);
    return result.moves;
  }
}
