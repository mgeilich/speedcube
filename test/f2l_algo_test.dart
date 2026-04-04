import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/cfop_solver.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final log = Logger('CfopTest');
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint("${record.level.name}: ${record.message}");
  });

  List<CubeMove> parse(String s) =>
      s.isEmpty ? [] : s.split(' ').map((m) => CubeMove.parse(m)!).toList();
  
  test('Full CFOP Solver Verification (U-layer scramble)', () {
    log.info("Starting U-layer only CFOP test");

    // A simple T-perm scramble to verify PLL
    final scramble = parse("R U R' U' R' F R2 U' R' U' R U R' F'");
    final testState = CubeState.yellowTopSolved().applyMoves(scramble);
    log.info("Scramble applied. F2L should be solved.");
    
    expect(_isF2lSolved(testState), true, reason: "Scramble should keep F2L solved");

    final result = CfopSolver.solve(testState);
    if (result == null) {
      fail("Solver returned null");
    }

    var curr = testState;
    for (var step in result.steps) {
      curr = curr.applyMoves(step.moves);
      log.info("After step: ${step.stageName} (${step.algorithmName ?? 'Manual'}) - ${step.moves.length} moves");
      if (!_isF2lSolved(curr)) {
          log.severe("F2L BROKEN after step ${step.stageName}");
      }
    }
    
    log.info("Final state solved: ${curr.isSolved}");
    log.info("Total moves: ${result.allMoves.length}");
    
    expect(curr.isSolved, true, reason: "Cube should be fully solved by CFOP");
  });
}

bool _isF2lSolved(CubeState s) {
    // Check if bottom face (White) is solved
    for (int i = 0; i < 9; i++) {
        if (s.d[i] != s.d[4]) return false;
    }
    // Check first two layers of side faces
    for (var faceStickers in [s.f, s.r, s.b, s.l]) {
        for (int i = 3; i < 9; i++) { // middle and bottom rows
            if (faceStickers[i] != faceStickers[4]) return false;
        }
    }
    return true;
}
