// ignore_for_file: avoid_print
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/kociemba_coordinates.dart';

void main() {
  CubeState s = CubeState.solved().applyMoves([
    CubeMove.f,
    CubeMove.b,
    CubeMove.r,
    CubeMove.l,
  ]);

  print("Initial bad count: ${KociembaCube.fromCubeState(s).badEdgeCount}");

  // Inverse moves
  final moves = [
    CubeMove.lPrime,
    CubeMove.rPrime,
    CubeMove.bPrime,
    CubeMove.fPrime,
  ];

  for (var m in moves) {
    s = s.applyMove(m);
    print(
        "After ${m.toString().split('.').last}: bad count ${KociembaCube.fromCubeState(s).badEdgeCount}");
  }
}
