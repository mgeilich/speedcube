import '../models/cube_move.dart';

/// A fast solver that reverses the scramble moves.
///
/// For a demo/animation app, this is the most reliable approach:
/// - Tracks the moves used to scramble
/// - Solves by applying the inverse moves in reverse order
/// - Guaranteed to work instantly for any scramble
class ReverseSolver {
  final List<CubeMove> _scrambleMoves = [];

  /// Record moves that were applied (for later reversal)
  void recordMoves(List<CubeMove> moves) {
    _scrambleMoves.addAll(moves);
  }

  /// Clear the recorded moves (e.g., on reset)
  void clear() {
    _scrambleMoves.clear();
  }

  /// Get the solution by reversing the recorded moves
  List<CubeMove> solve() {
    if (_scrambleMoves.isEmpty) return [];

    // Reverse the list and invert each move
    final solution =
        _scrambleMoves.reversed.map((move) => move.inverse).toList();

    // Clear after solving
    _scrambleMoves.clear();

    return _optimizeMoves(solution);
  }

  /// Optimize moves by canceling redundant ones
  List<CubeMove> _optimizeMoves(List<CubeMove> moves) {
    return CubeMove.optimize(moves);
  }
}
