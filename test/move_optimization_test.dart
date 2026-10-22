import 'package:speedcube_ar/models/cube_move.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CubeMove.optimize', () {
    test('Empty list returns empty list', () {
      expect(CubeMove.optimize([]), []);
    });

    test('Identical moves combine into R2', () {
      final moves = [CubeMove.r, CubeMove.r];
      final optimized = CubeMove.optimize(moves);
      expect(optimized.length, 1);
      expect(optimized[0], CubeMove.r2);
    });

    test('R + R2 combines into RPrime', () {
      final moves = [CubeMove.r, CubeMove.r2];
      final optimized = CubeMove.optimize(moves);
      expect(optimized.length, 1);
      expect(optimized[0], CubeMove.rPrime);
    });

    test('R2 + R2 cancels out', () {
      final moves = [CubeMove.r2, CubeMove.r2];
      final optimized = CubeMove.optimize(moves);
      expect(optimized.isEmpty, true);
    });

    test('R + RPrime cancels out', () {
      final moves = [CubeMove.r, CubeMove.rPrime];
      final optimized = CubeMove.optimize(moves);
      expect(optimized.isEmpty, true);
    });

    test('Multiple disparate moves remain untouched', () {
      final moves = [CubeMove.r, CubeMove.u, CubeMove.f];
      final optimized = CubeMove.optimize(moves);
      expect(optimized, moves);
    });

    test('Complex sequence simplifies correctly', () {
      // R U U' R R = R2
      final moves = [CubeMove.r, CubeMove.u, CubeMove.uPrime, CubeMove.r];
      final optimized = CubeMove.optimize(moves);
      expect(optimized.length, 1);
      expect(optimized[0], CubeMove.r2);
    });

    test('Wide moves combine correctly', () {
      final moves = [CubeMove.parse("Rw")!, CubeMove.parse("Rw")!];
      final optimized = CubeMove.optimize(moves);
      expect(optimized.length, 1);
      expect(optimized[0], CubeMove.parse("Rw2")!);
    });
    
    test('Identity moves are removed', () {
      final moves = [CubeMove(CubeFace.u, 4)];
      final optimized = CubeMove.optimize(moves);
      expect(optimized.isEmpty, true);
    });
  });
}
