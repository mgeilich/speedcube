import 'package:flutter_test/flutter_test.dart';
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/roux_solver.dart';
import 'package:logging/logging.dart';

final _log = Logger('RouxLogicTest');

void main() {
  test("Roux Solver Reliability Test - Complex Scrambles", () {
    _log.info("--- Testing Roux with Failing 20-move Scramble ---");
    final scrambleStr = "D' F D B D B' L' F B' R D F' D B F' R' L' D' F' R'";
    final scramble = scrambleStr.split(" ").map((s) => CubeMove.parse(s)).whereType<CubeMove>().toList();
    _log.info("Scramble: $scrambleStr");
    
    var state = CubeState.solved().applyMoves(scramble);
    
    final stopwatch = Stopwatch()..start();
    final result = RouxSolver.solve(state);
    stopwatch.stop();
    
    if (result == null) {
       _log.info("FAILURE: Solver returned null for 20-move scramble.");
       // Let's debug specifically why it failed.
       _log.info("Debugging orientations...");
       final orientations = RouxSolver.generateAll24Rotations();
       for (int i = 0; i < orientations.length; i++) {
         final oriented = state.applyMoves(orientations[i]);
         final fb = RouxSolver.findFBRealistic(oriented);
         if (fb == null) {
           _log.info("Orientation $i: FB Failed");
           final dl = RouxSolver.findDLEdge(oriented);
           if (dl == null) {
             _log.info("  DL Edge Failed");
           } else {
             _log.info("  DL Edge Solved. Next piece failed.");
           }
         } else {
           _log.info("Orientation $i: FB Solved. Checking SB...");
           final fbState = oriented.applyMoves(fb.expand((s) => s.moves).toList());
           final sb = RouxSolver.solveSBRealistic(fbState);
           if (sb == null) {
             _log.info("  SB Failed");
           } else {
             _log.info("  SB Solved! Checking CMLL...");
             final sbState = fbState.applyMoves(sb.expand((s) => s.moves).toList());
             final cmll = RouxSolver.findCMLL(sbState);
             if (cmll == null) {
                _log.info("    CMLL Failed");
             } else {
                _log.info("    CMLL Solved!");
             }
           }
         }
       }
       fail("Roux Solver returned null for a valid scramble.");
    } else {
       _log.info("SUCCESS: Found solution in ${stopwatch.elapsedMilliseconds}ms");
       _log.info("Move Count: ${result.allMoves.length}");
       expect(result.allMoves.isNotEmpty, true);
       for (var step in result.steps) {
         if (step.moves.isNotEmpty) {
           _log.info("${step.stageName}: ${step.moves.map((m) => m.toString()).join(' ')}");
         }
       }
    }
  });
}
