// ignore_for_file: avoid_print
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';

void main() {
  print("--- Edge Adjacency Check ---");
  
  final s = CubeState.solved();
  
  // Inspect D face neighbors
  // D1 should be near F? D7 near B?
  // Let's apply a quarter turn to side faces and see what changes on D.
  
  print("\nApplying F turns...");
  var sF = s;
  for (int i=1; i<4; i++) {
    sF = sF.applyMove(CubeMove.parse("F")!);
    _printDiff("F $i", s, sF);
  }

  print("\nApplying B turns...");
  var sB = s;
  for (int i=1; i<4; i++) {
    sB = sB.applyMove(CubeMove.parse("B")!);
    _printDiff("B $i", s, sB);
  }
}

void _printDiff(String label, CubeState original, CubeState current) {
  print("Changes after $label:");
  for (final f in CubeFace.physicalFaces) {
    final orig = original.getFace(f);
    final cur = current.getFace(f);
    List<int> diffs = [];
    for (int i=0; i<9; i++) {
      if (orig[i] != cur[i]) diffs.add(i);
    }
    if (diffs.isNotEmpty) {
      print("  Face ${f.name}: $diffs");
    }
  }
}
