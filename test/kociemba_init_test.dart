import 'package:speedcube_ar/solver/kociemba_coordinates.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:speedcube_ar/models/cube_state.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.message}');
  });
  final log = Logger('KociembaInitTest');

  test('KociembaCube fromCubeState test', () {
    final state = CubeState.solved();
    try {
      final cube = KociembaCube.fromCubeState(state);
      expect(cube.isSolved, true);
    } catch (e, stack) {
      log.severe("CRASH: $e", e, stack);
      rethrow;
    }
  });
}
