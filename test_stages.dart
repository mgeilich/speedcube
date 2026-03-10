// ignore_for_file: avoid_print
import 'lib/models/cube_state.dart';
import 'lib/models/cube_move.dart';
import 'lib/solver/kociemba_coordinates.dart';
import 'dart:math';
import 'dart:collection';

void main() {
  final random = Random(42);
  final faces = [
    CubeFace.u,
    CubeFace.d,
    CubeFace.f,
    CubeFace.b,
    CubeFace.r,
    CubeFace.l
  ];

  print("=== Testing Staged BFS for Last Layer ===\n");

  int passCount = 0;
  for (int t = 0; t < 20; t++) {
    var state = CubeState.solved();
    for (int j = 0; j < 20; j++) {
      state = state.applyMove(
          CubeMove(faces[random.nextInt(6)], [1, -1, 2][random.nextInt(3)]));
    }

    var cube = KociembaCube.fromCubeState(state);

    // F2L
    _solveDaisy(cube);
    _solveCross(cube);
    _solveWhiteCorners(cube);
    _solveMiddleLayer(cube);

    if (!_checkF2L(cube)) {
      print("Test $t: F2L FAILED");
      continue;
    }

    // LL Staged Solve
    try {
      _solveLLStaged(cube);

      if (cube.isSolved) {
        print("Test $t: PASS");
        passCount++;
      } else {
        print("Test $t: FAIL (Logic error)");
      }
    } catch (e) {
      print("Test $t: FAIL ($e)");
    }
  }

  print("\nStaged BFS Final result: $passCount / 20 passed\n");
}

void _solveLLStaged(KociembaCube cube) {
  // Stage 1: Edge Orientation (EO)
  // Goal: eo[4-7] == [0,0,0,0]
  // Moves: D, F R D R' D' F'
  _bfs(
      cube,
      (c) => c.eo.sublist(4, 8).every((e) => e == 0),
      [_parse("D"), _parse("D'"), _parse("D2"), _parse("F R D R' D' F'")],
      8 // Max depth (8 states total, very shallow)
      );

  // Stage 2: Edge Permutation (EP)
  // Goal: ep[4-7] == [4,5,6,7]
  // Moves: D, Sune
  // Preserves: EO, F2L
  _bfs(
      cube,
      (c) => c.ep.sublist(4, 8).join(',') == '4,5,6,7',
      [_parse("D"), _parse("D'"), _parse("D2"), _parse("R D R' D R D2 R'")],
      12);

  // Stage 3: Corner Permutation (CP)
  // Goal: cp[4-7] == [4,5,6,7]
  // Moves: D, Niklas
  // Preserves: EP, EO, F2L
  // Wait, D moves break ep[4-7] target!
  // So we only allow D moves if we re-align at the end.
  _bfs(cube, (c) {
    // Check if cp is correct relative to ep
    // Since ep is already [4,5,6,7], cp must be [4,5,6,7]
    return c.cp.sublist(4, 8).join(',') == '4,5,6,7';
  }, [
    _parse("D R D' L' D R' D' L"), // Niklas
    _parse("D"), _parse("D'"), _parse("D2") // Needed to align corners
  ], 12);

  // Re-align D layer if Niklas or D moves left it offset
  while (cube.ep[4] != 4) {
    cube.applyMove(CubeFace.d, 1);
  }

  // Stage 4: Corner Orientation (CO)
  // Goal: co[4-7] == [0,0,0,0]
  // Moves: TwistCommutator, D
  // Preserves: CP, EP, EO, F2L
  _bfs(
      cube,
      (c) => c.co.sublist(4, 8).every((e) => e == 0),
      [
        _parse(
            "R' D' R D R' D' R D D R' D' R D R' D' R D R' D' R D R' D' R D D'"), // Twist 4 CCW, 7 CW
        _parse(
            "R' D' R D R' D' R D R' D' R D R' D' R D D R' D' R D R' D' R D D'"), // Twist 4 CW, 7 CCW
        _parse("D"), _parse("D'"), _parse("D2")
      ],
      10);

  // Final Alignment
  while (cube.ep[4] != 4) {
    cube.applyMove(CubeFace.d, 1);
  }
}

void _bfs(KociembaCube cube, bool Function(KociembaCube) goal,
    List<List<CubeMove>> moves, int maxDepth) {
  if (goal(cube)) return;

  final queue = Queue<_Node>();
  queue.add(_Node(_clone(cube), []));
  final visited = <String>{};
  visited.add(_key(cube));

  while (queue.isNotEmpty) {
    final node = queue.removeFirst();
    if (node.path.length >= maxDepth) continue;

    for (final move in moves) {
      final next = _clone(node.cube);
      for (final m in move) {
        next.applyMove(m.face, m.turns);
      }

      if (goal(next)) {
        // Apply to original
        for (final p in [...node.path, move]) {
          for (final m in p) {
            cube.applyMove(m.face, m.turns);
          }
        }
        return;
      }

      final k = _key(next);
      if (!visited.contains(k)) {
        visited.add(k);
        queue.add(_Node(next, [...node.path, move]));
      }
    }
  }
  throw "Stage failed to solve";
}

List<CubeMove> _parse(String s) {
  final moves = <CubeMove>[];
  for (final part in s.split(' ')) {
    if (part.isEmpty) continue;
    final faceLetter = part[0];
    CubeFace face;
    switch (faceLetter) {
      case 'U':
        face = CubeFace.u;
        break;
      case 'D':
        face = CubeFace.d;
        break;
      case 'L':
        face = CubeFace.l;
        break;
      case 'R':
        face = CubeFace.r;
        break;
      case 'F':
        face = CubeFace.f;
        break;
      case 'B':
        face = CubeFace.b;
        break;
      default:
        throw "Unknown face $faceLetter";
    }
    int turns = 1;
    if (part.length > 1) {
      if (part[1] == "'") {
        turns = -1;
      } else if (part[1] == "2") {
        turns = 2;
      }
    }
    moves.add(CubeMove(face, turns));
  }
  return moves;
}

class _Node {
  final KociembaCube cube;
  final List<List<CubeMove>> path;
  _Node(this.cube, this.path);
}

String _key(KociembaCube c) {
  return "${c.ep.sublist(4, 8)}-${c.eo.sublist(4, 8)}-${c.cp.sublist(4, 8)}-${c.co.sublist(4, 8)}";
}

KociembaCube _clone(KociembaCube c) {
  var cube = KociembaCube();
  cube.ep.setAll(0, c.ep);
  cube.eo.setAll(0, c.eo);
  cube.cp.setAll(0, c.cp);
  cube.co.setAll(0, c.co);
  return cube;
}

bool _checkF2L(KociembaCube cube) {
  for (int i = 0; i < 4; i++) {
    if (cube.cp[i] != i || cube.co[i] != 0) return false;
    if (cube.ep[i] != i || cube.eo[i] != 0) return false;
  }
  for (int i = 8; i < 12; i++) {
    if (cube.ep[i] != i || cube.eo[i] != 0) return false;
  }
  return true;
}

void _solveDaisy(KociembaCube cube) {
  for (int eIdx = 0; eIdx < 4; eIdx++) {
    for (int s = 0; s < 40; s++) {
      int pos = _findEdgePos(cube, eIdx);
      if (pos >= 4 && pos <= 7 && cube.eo[pos] == 0) break;
      if (pos < 4) {
        _ensureDaisySpotSafe(cube, [4, 5, 6, 7][pos]);
        cube.applyMove(
            [CubeFace.r, CubeFace.f, CubeFace.l, CubeFace.b][pos], 2);
      } else if (pos >= 4 && pos <= 7) {
        cube.applyMove(
            [CubeFace.r, CubeFace.f, CubeFace.l, CubeFace.b][pos - 4], 1);
      } else {
        int eo = cube.eo[pos];
        int ts = (pos == 8)
            ? ((eo == 0) ? 4 : 5)
            : (pos == 9)
                ? ((eo == 0) ? 6 : 5)
                : (pos == 10)
                    ? ((eo == 0) ? 6 : 7)
                    : ((eo == 0) ? 4 : 7);
        _ensureDaisySpotSafe(cube, ts);
        if (pos == 8) {
          if (eo == 0) {
            cube.applyMove(CubeFace.r, -1);
          } else {
            cube.applyMove(CubeFace.f, 1);
          }
        } else if (pos == 9) {
          if (eo == 0) {
            cube.applyMove(CubeFace.l, 1);
          } else {
            cube.applyMove(CubeFace.f, -1);
          }
        } else if (pos == 10) {
          if (eo == 0) {
            cube.applyMove(CubeFace.l, -1);
          } else {
            cube.applyMove(CubeFace.b, -1);
          }
        } else {
          if (eo == 0) {
            cube.applyMove(CubeFace.r, 1);
          } else {
            cube.applyMove(CubeFace.b, 1);
          }
        }
      }
    }
  }
}

void _solveCross(KociembaCube cube) {
  for (int eIdx = 0; eIdx < 4; eIdx++) {
    if (_findEdgePos(cube, eIdx) == eIdx && cube.eo[eIdx] == 0) continue;
    while (_findEdgePos(cube, eIdx) != eIdx + 4) {
      cube.applyMove(CubeFace.d, 1);
    }
    cube.applyMove([CubeFace.r, CubeFace.f, CubeFace.l, CubeFace.b][eIdx], 2);
  }
}

void _solveWhiteCorners(KociembaCube cube) {
  for (int cIdx = 0; cIdx < 4; cIdx++) {
    for (int safety = 0; safety < 30; safety++) {
      int pos = _findCornerPos(cube, cIdx);
      if (pos == cIdx && cube.co[cIdx] == 0) break;
      if (pos < 4) {
        CubeFace r = [CubeFace.r, CubeFace.f, CubeFace.l, CubeFace.b][pos];
        cube.applyMove(r, -1);
        cube.applyMove(CubeFace.d, -1);
        cube.applyMove(r, 1);
      } else {
        while (_findCornerPos(cube, cIdx) != cIdx + 4) {
          cube.applyMove(CubeFace.d, 1);
        }
        CubeFace r = [CubeFace.r, CubeFace.f, CubeFace.l, CubeFace.b][cIdx];
        for (int i = 0; i < 6; i++) {
          if (_findCornerPos(cube, cIdx) == cIdx && cube.co[cIdx] == 0) break;
          cube.applyMove(r, -1);
          cube.applyMove(CubeFace.d, -1);
          cube.applyMove(r, 1);
          cube.applyMove(CubeFace.d, 1);
        }
      }
    }
  }
}

void _solveMiddleLayer(KociembaCube cube) {
  for (int eIdx = 8; eIdx < 12; eIdx++) {
    for (int safety = 0; safety < 30; safety++) {
      int pos = _findEdgePos(cube, eIdx);
      if (pos == eIdx && cube.eo[pos] == 0) break;
      if (pos >= 8) {
        _applyInsert(cube, pos);
      } else if (pos >= 4 && pos <= 7) {
        int targetDSlot = (eIdx == 8 || eIdx == 9) ? 5 : 7;
        while (_findEdgePos(cube, eIdx) != targetDSlot) {
          cube.applyMove(CubeFace.d, 1);
        }
        _applyInsert(cube, eIdx);
      } else {
        cube.applyMove(
            [CubeFace.r, CubeFace.f, CubeFace.l, CubeFace.b][pos], 1);
      }
    }
  }
}

void _applyInsert(KociembaCube cube, int targetSlot) {
  if (targetSlot == 8) {
    cube.applyMove(CubeFace.d, -1);
    cube.applyMove(CubeFace.r, -1);
    cube.applyMove(CubeFace.d, 1);
    cube.applyMove(CubeFace.r, 1);
    cube.applyMove(CubeFace.d, 1);
    cube.applyMove(CubeFace.f, 1);
    cube.applyMove(CubeFace.d, -1);
    cube.applyMove(CubeFace.f, -1);
  } else if (targetSlot == 9) {
    cube.applyMove(CubeFace.d, 1);
    cube.applyMove(CubeFace.l, 1);
    cube.applyMove(CubeFace.d, -1);
    cube.applyMove(CubeFace.l, -1);
    cube.applyMove(CubeFace.d, -1);
    cube.applyMove(CubeFace.f, -1);
    cube.applyMove(CubeFace.d, 1);
    cube.applyMove(CubeFace.f, 1);
  } else if (targetSlot == 10) {
    cube.applyMove(CubeFace.d, -1);
    cube.applyMove(CubeFace.l, -1);
    cube.applyMove(CubeFace.d, 1);
    cube.applyMove(CubeFace.l, 1);
    cube.applyMove(CubeFace.d, 1);
    cube.applyMove(CubeFace.b, 1);
    cube.applyMove(CubeFace.d, -1);
    cube.applyMove(CubeFace.b, -1);
  } else {
    cube.applyMove(CubeFace.d, 1);
    cube.applyMove(CubeFace.r, 1);
    cube.applyMove(CubeFace.d, -1);
    cube.applyMove(CubeFace.r, -1);
    cube.applyMove(CubeFace.d, -1);
    cube.applyMove(CubeFace.b, -1);
    cube.applyMove(CubeFace.d, 1);
    cube.applyMove(CubeFace.b, 1);
  }
}

void _ensureDaisySpotSafe(KociembaCube cube, int spot) {
  for (int i = 0; i < 4; i++) {
    if (cube.ep[spot] >= 4 || cube.eo[spot] != 0) return;
    cube.applyMove(CubeFace.d, 1);
  }
}

int _findEdgePos(KociembaCube cube, int eIdx) {
  for (int i = 0; i < 12; i++) {
    if (cube.ep[i] == eIdx) return i;
  }
  return -1;
}

int _findCornerPos(KociembaCube cube, int cIdx) {
  for (int i = 0; i < 8; i++) {
    if (cube.cp[i] == cIdx) return i;
  }
  return -1;
}
