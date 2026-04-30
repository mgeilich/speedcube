import 'package:speedcube_ar/solver/heise_solver.dart';
import 'package:speedcube_ar/solver/kociemba_tables.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/solver/zz_solver.dart';

void main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.message}');
  });
  final log = Logger('DebugCrashes');

  log.info("Initializing tables...");
  await KociembaTables.init();
  
  final scramble = CubeState.generateScramble(20);
  final state = CubeState.solved().applyMoves(scramble);
  
  log.info("--- Testing Heise ---");
  try {
    final res = await HeiseSolver.solve(state);
    log.info("Heise: ${res.steps.length} steps");
  } catch (e, s) {
    log.severe("Heise CRASHED: $e", e, s);
  }

  log.info("--- Testing ZZ ---");
  try {
    final res = await ZzSolver.solve(state);
    log.info("ZZ: ${res?.steps.length ?? 'null'} steps");
  } catch (e, s) {
    log.severe("ZZ CRASHED: $e", e, s);
  }
}
