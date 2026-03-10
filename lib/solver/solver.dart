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
    if (moves.isEmpty) return moves;

    final result = <CubeMove>[];
    for (final move in moves) {
      if (result.isEmpty) {
        result.add(move);
        continue;
      }

      final last = result.last;
      if (last.face == move.face) {
        result.removeLast();
        int totalTurns = last.turns + move.turns;
        // Normalize to -1, 1, or 2
        while (totalTurns > 2) {
          totalTurns -= 4;
        }
        while (totalTurns < -1) {
          totalTurns += 4;
        }
        if (totalTurns == 1) {
          result.add(CubeMove(move.face, 1));
        } else if (totalTurns == 2 || totalTurns == -2) {
          result.add(CubeMove(move.face, 2));
        } else if (totalTurns == -1 || totalTurns == 3) {
          result.add(CubeMove(move.face, -1));
        }
        // If totalTurns == 0 or 4, the moves cancel out
      } else {
        result.add(move);
      }
    }

    return result;
  }
}
