import '../models/cube_state.dart';
import '../models/cube_move.dart';
import '../solver/kociemba_search.dart';
import '../solver/lbl_solver.dart';
import '../solver/cfop_solver.dart';
import '../solver/roux_solver.dart';
import '../solver/zz_solver.dart';
import '../solver/petrus_solver.dart';
import '../solver/heise_solver.dart';
import '../models/solve_method.dart';

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
    void Function(String)? onProgress,
  }) async {
    switch (method) {
      case SolveMethod.petrus:
        final result = await PetrusSolver.solve(state, onProgress: onProgress);
        
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
      case SolveMethod.heise:
        final result = await HeiseSolver.solve(state, onProgress: onProgress);
        
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

      case SolveMethod.roux:
        final result = await RouxSolver.solve(state, onProgress: onProgress);
        
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

      case SolveMethod.zz:
        final result = await ZzSolver.solve(state, onProgress: onProgress);
        
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

      case SolveMethod.lbl:
        final result = await LblSolver.solve(state, onProgress: onProgress);
        
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

      case SolveMethod.cfop:
        final result = await CfopSolver.solve(state, onProgress: onProgress);
        
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

      case SolveMethod.kociemba:
        final result = await KociembaSolver.solve(state);
        return SolveResult(
          moves: result.moves,
          phase1MoveCount: result.phase1MoveCount,
        );
    }
  }
}
