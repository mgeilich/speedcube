import '../models/cube_move.dart';

/// A single step in the solution, with stage label and description.
class LblStep {
  final String stageName;
  final List<CubeMove> moves;
  final String description;
  final String? algorithmName;

  const LblStep({
    required this.stageName,
    required this.moves,
    required this.description,
    this.algorithmName,
  });
}

/// Result of a solver (Beginner or CFOP).
class LblSolveResult {
  final List<LblStep> steps;
  List<CubeMove> get allMoves => steps.expand((s) => s.moves).toList();
  int get totalMoves => allMoves.length;
  const LblSolveResult({required this.steps});
}
