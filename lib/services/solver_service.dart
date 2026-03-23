import '../models/cube_state.dart';
import '../models/cube_move.dart';
import '../solver/kociemba_search.dart';
import '../solver/lbl_solver.dart';
import '../controllers/home_controller.dart'; // For SolveMethod

class SolveResult {
  final List<CubeMove> moves;
  final int phase1MoveCount;
  final List<String?>? stageNames;
  final List<String?>? stageDescriptions;
  final List<String?>? algorithmNames;

  SolveResult({
    required this.moves,
    required this.phase1MoveCount,
    this.stageNames,
    this.stageDescriptions,
    this.algorithmNames,
  });
}

class SolverService {
  static Future<SolveResult> solve({
    required CubeState state,
    SolveMethod method = SolveMethod.kociemba,
  }) async {
    if (method == SolveMethod.lbl || method == SolveMethod.cfop) {
      final result = method == SolveMethod.lbl ? LblSolver.solve(state) : CfopSolver.solve(state);
      if (result != null) {
        final List<CubeMove> moves = result.allMoves;
        final List<String?> stageNames = [];
        final List<String?> stageDescriptions = [];
        final List<String?> algorithmNames = [];

        for (final step in result.steps) {
          for (int i = 0; i < step.moves.length; i++) {
            stageNames.add(step.stageName);
            stageDescriptions.add(step.description);
            algorithmNames.add(step.algorithmName);
          }
        }

        return SolveResult(
          moves: moves,
          phase1MoveCount: moves.length,
          stageNames: stageNames,
          stageDescriptions: stageDescriptions,
          algorithmNames: algorithmNames,
        );
      }
      return SolveResult(moves: [], phase1MoveCount: 0);
    } else {
      final result = await KociembaSolver.solve(state);
      return SolveResult(
        moves: result.moves,
        phase1MoveCount: result.phase1MoveCount,
      );
    }
  }
}
