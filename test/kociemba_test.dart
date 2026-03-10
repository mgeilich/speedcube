// ignore_for_file: avoid_print

import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/solver/kociemba_search.dart';

void main() async {
  print('Starting exhaustive Kociemba solver test (100 runs)...');
  int successCount = 0;

  for (int i = 0; i < 100; i++) {
    print('\n--- Test Run ${i + 1} ---');
    final state = CubeState.solved();
    final scramble = CubeState.generateScramble(20);
    final scrambledState = state.applyMoves(scramble);

    print('Scramble: ${scramble.join(" ")}');

    final startTime = DateTime.now();
    final result = await KociembaSolver.solve(scrambledState);
    final solution = result.moves;
    final endTime = DateTime.now();

    print(
        'Solution found in ${endTime.difference(startTime).inMilliseconds}ms');
    print('Solution length: ${solution.length}');
    print('Solution: ${solution.join(" ")}');

    final finalState = scrambledState.applyMoves(solution);
    if (finalState.isSolved) {
      print('SUCCESS: Cube solved!');
      successCount++;
    } else {
      print('FAILURE: Cube NOT solved.');
    }
  }
  print('\nBatch test finished. Success rate: $successCount / 100');
}
