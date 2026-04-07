import 'package:logging/logging.dart';
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/solver/cfop_solver.dart';

void main() {
  // Initialize logging for the standalone script
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.message}');
  });
  
  final log = Logger('TestCfopCross');

  for (int i = 0; i < 5; i++) {
    log.info('--- Test #$i ---');
    var scramble = CubeState.generateScramble(20);
    var solveResult = CfopSolver.solve(CubeState.solved().applyMoves(scramble));
    
    if (solveResult == null) {
      log.severe('FAILED: Solve result is null');
      continue;
    }
    
    var crossSteps = solveResult.steps.where((s) => s.stageName == 'Advanced Cross' || s.stageName == 'CFOP Cross');
    if (crossSteps.isEmpty) {
        log.severe('FAILED: No cross step found');
    } else {
        var crossStep = crossSteps.first;
        log.info('Stage: ${crossStep.stageName}');
        log.info('Moves (${crossStep.moves.length}): ${crossStep.moves}');
    }
  }
}
