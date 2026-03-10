import 'package:logging/logging.dart';
import 'lib/utils/logging_config.dart';
import 'lib/models/cube_state.dart';
import 'lib/models/cube_move.dart';

void main() {
  initLogging();
  final log = Logger('TestLbl');

  // Test: For each D corner, what algorithm inserts from above?
  // DFR: piece at UFR → R U R' U' (or R' D' R D in some methods)
  // DFL: piece at UFL → L' U' L U
  // DRB: piece at UBR → B U B' U' (R from R's perspective? No...)
  // DBL: piece at UBL → ...

  // Actually the beginner's method says: always use R U R' U' but hold the
  // cube so the target slot is at your front-right. So for DFL, you'd hold
  // the cube rotated so DFL is at your front-right = that means L face
  // becomes your front. But we can't rotate the cube, so we need the
  // equivalent moves.
  //
  // The equivalent of R U R' U' when the "front" is L:
  //   R → F (the face to the right of L is F)
  //   But this is F U F' U' which we showed doesn't work!
  //
  // The issue: R U R' U' inserts from UFR into DFR.
  // When front=L, "UFR" = ULF in absolute coords.
  // But the algorithm F U F' U' (R remapped for front=L) operates on
  // the ULF-DLF axis using the F face... which is wrong.
  //
  // The CORRECT approach: the R U R' U' algorithm works because R affects
  // the DFR corner. For DFL, we need L' U' L U (the mirror algorithm).
  // For DRB, we need B' U' B U? No...
  //
  // Let me just test all the standard corner insertions:

  log.info('=== DFR: R U R\' U\' ===');
  _testCornerInsert(
    CubeFace.f, CubeFace.r, // target slot
    2, 8, 6, // D idx, front idx, right idx
    [CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime],
    log,
  );

  log.info('\n=== DFL: L\' U\' L U ===');
  _testCornerInsert(
    CubeFace.f, CubeFace.l, // target slot
    0, 6, 8, // D idx, front idx, left idx
    [CubeMove.lPrime, CubeMove.uPrime, CubeMove.l, CubeMove.u],
    log,
  );

  log.info('\n=== DRB: B\' U\' B U ===');
  _testCornerInsert(
    CubeFace.b,
    CubeFace.r,
    8,
    6,
    8,
    [CubeMove.bPrime, CubeMove.uPrime, CubeMove.b, CubeMove.u],
    log,
  );

  log.info('\n=== DBL: B U B\' U\' ===');
  _testCornerInsert(
    CubeFace.b,
    CubeFace.l,
    6,
    8,
    6,
    [CubeMove.b, CubeMove.u, CubeMove.bPrime, CubeMove.uPrime],
    log,
  );
}

void _testCornerInsert(CubeFace face1, CubeFace face2, int dIdx, int f1Idx,
    int f2Idx, List<CubeMove> alg, Logger log) {
  var s = CubeState.solved();
  final targetD = s.d[dIdx];
  final targetF1 = s.getFace(face1)[f1Idx];
  final targetF2 = s.getFace(face2)[f2Idx];
  log.info(
      'Target: D[$dIdx]=$targetD, ${face1.name}[$f1Idx]=$targetF1, ${face2.name}[$f2Idx]=$targetF2');

  // Pop the corner out
  s = s.applyMoves(alg.sublist(0, 3)); // first 3 moves to pop
  log.info('After pop (first 3 moves of alg):');
  log.info(
      '  D[$dIdx]=${s.d[dIdx]}, ${face1.name}[$f1Idx]=${s.getFace(face1)[f1Idx]}, ${face2.name}[$f2Idx]=${s.getFace(face2)[f2Idx]}');

  // Now repeat the full algorithm
  for (int i = 1; i <= 8; i++) {
    s = s.applyMoves(alg);
    final ok = s.d[dIdx] == targetD &&
        s.getFace(face1)[f1Idx] == targetF1 &&
        s.getFace(face2)[f2Idx] == targetF2;
    log.info(
        'After ${i}x: D=${s.d[dIdx]}, ${face1.name}=${s.getFace(face1)[f1Idx]}, ${face2.name}=${s.getFace(face2)[f2Idx]} ${ok ? "SOLVED!" : ""}');
  }
}
