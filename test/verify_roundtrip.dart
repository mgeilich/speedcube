// ignore_for_file: avoid_print

import 'package:speedcube_ar/solver/kociemba_coordinates.dart';
import 'package:speedcube_ar/models/cube_move.dart';

void main() {
  print('Verifying KociembaCube round-trip consistency...');

  final cube = KociembaCube(); // Solved

  // Test 1: Solved round-trip
  if (!_checkRoundTrip(cube, 'Solved')) return;

  // Test 3: Random scramble
  print('Running random scramble test (100 moves)...');
  final rand = KociembaCube();
  final faces = CubeFace.values;
  // Use a fixed seed for reproducible failures if needed, but for now just run it.
  for (int i = 0; i < 100; i++) {
    final f = faces[i % faces.length];
    rand.applyMove(f, 1);
    if (!_checkRoundTrip(rand, 'Random Step $i (${f.name})')) return;
  }

  print('All round-trip checks PASSED!');
}

bool _checkRoundTrip(KociembaCube original, String label) {
  final state = original.toCubeState();
  final reconstructed = KociembaCube.fromCubeState(state);

  bool match = true;
  for (int i = 0; i < 8; i++) {
    if (reconstructed.cp[i] != original.cp[i] ||
        reconstructed.co[i] != original.co[i]) {
      print(
          'FAILED $label: Corner $i mismatch. Orig: cp=${original.cp[i]} co=${original.co[i]}, Rec: cp=${reconstructed.cp[i]} co=${reconstructed.co[i]}');
      match = false;
    }
  }
  for (int i = 0; i < 12; i++) {
    if (reconstructed.ep[i] != original.ep[i] ||
        reconstructed.eo[i] != original.eo[i]) {
      print(
          'FAILED $label: Edge $i mismatch. Orig: ep=${original.ep[i]} eo=${original.eo[i]}, Rec: ep=${reconstructed.ep[i]} eo=${reconstructed.eo[i]}');
      match = false;
    }
  }

  return match;
}
