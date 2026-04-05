// ignore_for_file: avoid_print
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/solver/cfop_solver.dart';

void main() {
  print('Testing CFOP Solver with Bottom Cross...');

  int successCount = 0;
  int totalTests = 20;

  for (int i = 0; i < totalTests; i++) {
    final scramble = CubeState.generateScramble(25);
    final initialState = CubeState.solved().applyMoves(scramble);
    
    final result = CfopSolver.solve(initialState);
    if (result == null) {
      print('Test ${i + 1}: FAILED (Solver returned null)');
      continue;
    }

    var currentState = initialState;

    for (final step in result.steps) {
      currentState = currentState.applyMoves(step.moves);
    }

    if (currentState.isSolved) {
      print('Test ${i + 1}: PASSED');
      successCount++;
    } else {
      print('Test ${i + 1}: FAILED');
      // Verify stages
      var s = initialState;
      final stages = ['Orientation', 'CFOP Cross', 'CFOP F2L', 'CFOP OLL', 'CFOP PLL'];
      for (final stage in stages) {
        final stageSteps =
            result.steps.where((st) => st.stageName.startsWith(stage)).toList();
        for (final st in stageSteps) {
          s = s.applyMoves(st.moves);
        }

        bool crossOk = CfopSolver.isCrossSolved(s, Perspective.identity);
        if (!crossOk && stage != 'Orientation' && stage != 'CFOP Cross') {
          print('    Cross broke at stage: $stage');
        }
      }
    }
  }

  print('\nSummary: $successCount / $totalTests passed.');
  if (successCount == totalTests) {
    print('ALL TESTS PASSED!');
  } else {
    print('SOME TESTS FAILED.');
  }
}
