// ignore_for_file: avoid_print
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/solver/beginner_solver.dart';

void main() async {
  print('Comparing Beginner (LBL) vs Kociemba solvers...');
  print('Testing with 20-move scrambles\n');

  int successCount = 0;
  int testCount = 10;

  for (int i = 0; i < testCount; i++) {
    print('--- Test Run ${i + 1} ---');

    final state = CubeState.solved();
    final scramble = CubeState.generateScramble(20);
    final scrambledState = state.applyMoves(scramble);

    print('Scramble: ${scramble.join(" ")}');

    // Test Beginner solver
    final solver = BeginnerSolver();
    final startTime = DateTime.now();
    final solution = await solver.solve(scrambledState);
    final endTime = DateTime.now();

    print(
        'Beginner solution found in ${endTime.difference(startTime).inMilliseconds}ms');
    print('Beginner solution length: ${solution.length}');

    final finalState = scrambledState.applyMoves(solution);
    if (finalState.isSolved) {
      print('✓ SUCCESS: Cube solved with Beginner method!');
      successCount++;
    } else {
      print('✗ FAILURE: Cube NOT solved with Beginner method.');
      print('Solution was: ${solution.join(" ")}');
    }
    print('');
  }

  print('Beginner solver success rate: $successCount / $testCount');
  if (successCount == testCount) {
    print('✓ All tests passed!');
  } else {
    print('✗ Some tests failed.');
  }
}
