import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/solver/heise_solver.dart';
import 'package:speedcube_ar/solver/kociemba_tables.dart';
import 'package:speedcube_ar/solver/kociemba_coordinates.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/models/solve_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Heise Stage 5 should always leave exactly 3 corners', () async {
    debugPrint("Initializing tables...");
    await KociembaTables.init();
    
    debugPrint("\nTest Case: U move scramble (preserves Stages 1-4)");
    var state = CubeState.solved().applyMoves([CubeMove.u]); // Just a U turn
    
    final result = await HeiseSolver.solve(state);
    
    debugPrint("  Solve steps: ${result.steps.map((s) => s.stageName).toList()}");
    
    expect(result.steps.isNotEmpty, true, reason: "Solver should find a solution");
    
    // Find Stage 5
    LblStep? stage5;
    for (var step in result.steps) {
      if (step.stageName == "Two Pairs & Edges") {
        stage5 = step;
        break;
      }
    }
    
    expect(stage5 != null, true, reason: "Stage 5 should be present for a U-scramble");
    
    // Reconstruct state at end of Stage 5
    var testState = state;
    for (final step in result.steps) {
      testState = testState.applyMoves(step.moves);
      if (step.stageName == "Two Pairs & Edges") break;
    }
    
    final k = KociembaCube.fromCubeState(testState);
    final unsolved = k.unsolvedCornerCount;
    
    debugPrint("  Stage 5 result moves: ${stage5!.moves}");
    debugPrint("  Unsolved corners at end of Stage 5: $unsolved");
    
    expect(unsolved, 3, reason: "Stage 5 should result in exactly 3 unsolved corners");
    expect(testState.isSolved, false, reason: "Cube should NOT be solved at end of Stage 5");
    
    // Check if Stage 6 follows
    final stage6 = result.steps.last;
    expect(stage6.stageName, "The Commutator Finish");
    
    final finalState = testState.applyMoves(stage6.moves);
    expect(finalState.isSolved, true, reason: "Final step should solve the cube");
    debugPrint("  SUCCESS: Full solve transition verified.");
  });
}
