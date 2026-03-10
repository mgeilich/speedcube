// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:speedcube_ar/models/cube_state.dart';
import 'package:speedcube_ar/models/cube_move.dart';

void main() {
  group('CubeState', () {
    test('solved cube is detected as solved', () {
      final cube = CubeState.solved();
      expect(cube.isSolved, isTrue);
    });

    test('applying a move changes state', () {
      final cube = CubeState.solved();
      final moved = cube.applyMove(CubeMove.r);
      expect(moved.isSolved, isFalse);
    });

    test('R R R R returns to solved', () {
      var cube = CubeState.solved();
      cube = cube.applyMove(CubeMove.r);
      cube = cube.applyMove(CubeMove.r);
      cube = cube.applyMove(CubeMove.r);
      cube = cube.applyMove(CubeMove.r);
      expect(cube.isSolved, isTrue);
    });

    test('R R\' cancels out', () {
      var cube = CubeState.solved();
      cube = cube.applyMove(CubeMove.r);
      cube = cube.applyMove(CubeMove.rPrime);
      expect(cube.isSolved, isTrue);
    });

    test('scramble generates correct number of moves', () {
      final scramble = CubeState.generateScramble(15);
      expect(scramble.length, equals(15));
    });

    test('scramble has no consecutive same-face moves', () {
      final scramble = CubeState.generateScramble(20);
      for (int i = 1; i < scramble.length; i++) {
        expect(scramble[i].face, isNot(equals(scramble[i - 1].face)));
      }
    });
  });

  group('CubeMove', () {
    test('parse R correctly', () {
      final move = CubeMove.parse('R');
      expect(move?.face, equals(CubeFace.r));
      expect(move?.turns, equals(1));
    });

    test('parse R\' correctly', () {
      final move = CubeMove.parse("R'");
      expect(move?.face, equals(CubeFace.r));
      expect(move?.turns, equals(-1));
    });

    test('parse R2 correctly', () {
      final move = CubeMove.parse('R2');
      expect(move?.face, equals(CubeFace.r));
      expect(move?.turns, equals(2));
    });

    test('inverse of R is R\'', () {
      expect(CubeMove.r.inverse, equals(CubeMove.rPrime));
    });

    test('inverse of R2 is R2', () {
      expect(CubeMove.r2.inverse, equals(CubeMove.r2));
    });

    test('toString formats correctly', () {
      expect(CubeMove.r.toString(), equals('R'));
      expect(CubeMove.rPrime.toString(), equals("R'"));
      expect(CubeMove.r2.toString(), equals('R2'));
    });
  });
}
