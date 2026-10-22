import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/services/solver_service.dart';
import 'package:speedcube_ar/models/solve_method.dart';
import 'package:logging/logging.dart';

final _log = Logger('RouxRepro');

void main() async {
  _log.info("Starting Roux Solver test...");
  
  // Try a simple scramble: M U M' U' (standard H-perm slice start or similar)
  // Actually, Roux is color neutral, so let's just do a 3 move scramble.
  final scramble = [
    const CubeMove(CubeFace.r, 1),
    const CubeMove(CubeFace.u, 1),
    const CubeMove(CubeFace.f, 1),
  ];
  
  var state = CubeState.solved();
  state = state.applyMoves(scramble);
  
  _log.info("Scramble applied. Starting solve...");
  
  final result = await SolverService.solve(state: state, method: SolveMethod.roux);
  
  _log.info("Solve completed!");
  _log.info("Moves: ${result.moves.length}");
  for (final move in result.moves) {
    _log.info(move);
  }
}
