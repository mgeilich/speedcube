import '../models/cube_state.dart';
import '../models/cube_move.dart';
import '../models/solve_result.dart';
import '../solver/kociemba_search.dart';
import '../solver/lbl_solver.dart';
import '../solver/cfop_solver.dart';
import '../solver/roux_solver.dart';
import 'package:flutter/foundation.dart';
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

class _SolveParams {
  final CubeState state;
  final SolveMethod method;
  _SolveParams(this.state, this.method);
}

class SolverService {
  static Future<SolveResult> solve({
    required CubeState state,
    SolveMethod method = SolveMethod.kociemba,
  }) async {
    switch (method) {
      case SolveMethod.lbl:
      case SolveMethod.cfop:
      case SolveMethod.roux:
        final result = await compute(_runSolver, _SolveParams(state, method));

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

  static LblSolveResult? _runSolver(_SolveParams params) {
    switch (params.method) {
      case SolveMethod.lbl:
        return LblSolver.solve(params.state);
      case SolveMethod.cfop:
        return CfopSolver.solve(params.state);
      case SolveMethod.roux:
        return RouxSolver.solve(params.state);
      default:
        return null;
    }
  }
}
