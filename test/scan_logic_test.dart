import 'package:flutter_test/flutter_test.dart';
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';
import 'package:speedcube_ar/solver/kociemba_search.dart';

void main() {
  setUpAll(() async {
    // Ensure tables are loaded before running solver tests
    await KociembaSolver.init();
  });

  group('Scan Logic Verification', () {
    test('Reconstructing solved cube from faces should result in isSolved=true',
        () {
      final solved = CubeState.solved();

      final reconstructed = CubeState.fromFaces(
        u: List.from(solved.u),
        d: List.from(solved.d),
        f: List.from(solved.f),
        b: List.from(solved.b),
        r: List.from(solved.r),
        l: List.from(solved.l),
      );

      expect(reconstructed.isSolved, isTrue);
      expect(reconstructed.toString(), equals(solved.toString()));
    });

    test('Reconstructing scrambled cube from faces should be solvable',
        () async {
      // 1. Create a known scramble
      final scramble = [
        CubeMove(CubeFace.r, 1), // R
        CubeMove(CubeFace.u, 1), // U
        CubeMove(CubeFace.r, -1), // R'
        CubeMove(CubeFace.u, -1), // U'
      ];

      final originalState = CubeState.solved().applyMoves(scramble);

      // 2. Simulate "Scanning" (extracting face data)
      final u = List<CubeColor>.from(originalState.u);
      final d = List<CubeColor>.from(originalState.d);
      final f = List<CubeColor>.from(originalState.f);
      final b = List<CubeColor>.from(originalState.b);
      final r = List<CubeColor>.from(originalState.r);
      final l = List<CubeColor>.from(originalState.l);

      // 3. Reconstruct using the same factory the AR Scan screen uses
      final scannedState = CubeState.fromFaces(
        u: u,
        d: d,
        f: f,
        b: b,
        r: r,
        l: l,
      );

      // 4. Verify the identity
      expect(scannedState.toString(), equals(originalState.toString()),
          reason:
              'The reconstructed state must exactly match the state it was extracted from');

      // 5. Verify it is solvable
      final result = await KociembaSolver.solve(scannedState);
      final solution = result.moves;
      expect(solution, isNotEmpty,
          reason: 'A correctly scanned cube must have a solution');

      final solvedState = scannedState.applyMoves(solution);
      expect(solvedState.isSolved, isTrue,
          reason: 'Applying the solution must result in a solved cube');
    });

    test('Exhaustive Random Scramble Scan Test', () async {
      for (int i = 0; i < 10; i++) {
        final scramble = CubeState.generateScramble(20);
        final originalState = CubeState.solved().applyMoves(scramble);

        final scannedState = CubeState.fromFaces(
          u: List.from(originalState.u),
          d: List.from(originalState.d),
          f: List.from(originalState.f),
          b: List.from(originalState.b),
          r: List.from(originalState.r),
          l: List.from(originalState.l),
        );

        final result = await KociembaSolver.solve(scannedState);
        final solution = result.moves;
        expect(solution, isNotEmpty);

        final solvedState = scannedState.applyMoves(solution);
        expect(solvedState.isSolved, isTrue);
      }
    });
  });
}
