import '../models/cube_state.dart';
import '../models/cube_move.dart';
import '../models/solve_result.dart';
import 'kociemba_coordinates.dart';
import 'kociemba_search.dart';
import 'dart:collection';

class PetrusStep extends LblStep {
  const PetrusStep({
    required super.stageName,
    required super.moves,
    super.algorithmName,
    required super.description,
  });
}

class PetrusSolver {
  static Future<LblSolveResult> solve(CubeState state) async {
    final steps = <LblStep>[];
    final currentCube = KociembaCube.fromCubeState(state);

    // Stage 1: 2x2x2 Block
    final s1Moves = solve2x2x2(currentCube);
    if (s1Moves.isNotEmpty) {
      steps.add(LblStep(
        stageName: "2x2x2 Block",
        moves: s1Moves,
        description: "Build a 2x2x2 block in the back-down-left corner.",
      ));
      for (final m in s1Moves) {
        currentCube.applyMove(m.face, m.turns);
      }
    }

    // Stage 2: 2x2x3 Block
    final s2Moves = solve2x2x3(currentCube);
    if (s2Moves.isNotEmpty) {
      steps.add(LblStep(
        stageName: "2x2x3 Expansion",
        moves: s2Moves,
        description: "Expand the 2x2x2 block to a 2x2x3 block.",
      ));
      for (final m in s2Moves) {
        currentCube.applyMove(m.face, m.turns);
      }
    }

    // Stage 3: Edge Orientation
    final s3Moves = solveEO(currentCube);
    if (s3Moves.isNotEmpty) {
      steps.add(LblStep(
        stageName: "Edge Orientation",
        moves: s3Moves,
        description: "Orient all remaining edges to simplify the rest of the solve.",
      ));
      for (final m in s3Moves) {
        currentCube.applyMove(m.face, m.turns);
      }
    }

    // Stage 4: Finish F2L
    final s4Moves = solveF2L(currentCube);
    if (s4Moves.isNotEmpty) {
      steps.add(LblStep(
        stageName: "Finish F2L",
        moves: s4Moves,
        description: "Complete the first two layers without disturbing oriented edges.",
      ));
      for (final m in s4Moves) {
        currentCube.applyMove(m.face, m.turns);
      }
    }

    // Stage 5: Last Layer
    final currentState = state.applyMoves(steps.expand((s) => s.moves).toList());
    final s5Moves = await solveLL(currentState);
    if (s5Moves.isNotEmpty) {
      steps.add(LblStep(
        stageName: "Last Layer",
        moves: s5Moves,
        description: "Solve the final layer using orientation and permutation.",
      ));
    }

    return LblSolveResult(steps: steps);
  }

  static Future<List<CubeMove>> solveLL(CubeState state) async {
    if (state.isSolved) return [];
    
    // Kociemba solver is incredibly reliable and fast for the last layer.
    final search = KociembaSearch(timeLimitMs: 400);
    final result = await search.solve(state);
    return result?.moves ?? [];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STAGES
  // ─────────────────────────────────────────────────────────────────────────

  static List<CubeMove> solve2x2x2(KociembaCube cube) {
    final moves = <CubeMove>[];
    final working = KociembaCube.clone(cube);

    // Step 1a: Solve dBL corner and dL, dB edges
    final s1a = _bfs(working, (c) => 
      c.cp[6] == 6 && c.co[6] == 0 && 
      c.ep[6] == 6 && c.eo[6] == 0 &&
      c.ep[7] == 7 && c.eo[7] == 0, 
      _allMoves, 7);
    if (s1a != null) {
      moves.addAll(s1a);
      for (final m in s1a) {
        working.applyMove(m.face, m.turns);
      }
    } else {
      return []; // Failed
    }

    // Step 1b: Solve bL edge while preserving 1a
    final s1b = _bfs(working, (c) => 
      c.cp[6] == 6 && c.co[6] == 0 && 
      c.ep[6] == 6 && c.eo[6] == 0 &&
      c.ep[7] == 7 && c.eo[7] == 0 &&
      c.ep[10] == 10 && c.eo[10] == 0,
      _allMoves, 7);
    if (s1b != null) {
      moves.addAll(s1b);
    } else {
      return []; // Failed
    }

    return moves;
  }

  static List<CubeMove> solve2x2x3(KociembaCube cube) {
    bool isSolved(KociembaCube c) {
      if (!(c.cp[6] == 6 && c.co[6] == 0 && c.ep[6] == 6 && c.eo[6] == 0 &&
            c.ep[7] == 7 && c.eo[7] == 0 && c.ep[10] == 10 && c.eo[10] == 0)) {
        return false;
      }
      return c.cp[5] == 5 && c.co[5] == 0 && c.ep[5] == 5 && c.eo[5] == 0 && c.ep[9] == 9 && c.eo[9] == 0;
    }
    // Only U, R, F preserve the dBL 2x2x2
    return _bfs(cube, isSolved, _urfMoves, 9) ?? [];
  }

  static List<CubeMove> solveEO(KociembaCube cube) {
    bool isSolved(KociembaCube c) {
      // Must preserve 2x2x3
      if (!(c.cp[6] == 6 && c.co[6] == 0 && c.ep[6] == 6 && c.eo[6] == 0 &&
            c.ep[7] == 7 && c.eo[7] == 0 && c.ep[10] == 10 && c.eo[10] == 0 &&
            c.cp[5] == 5 && c.co[5] == 0 && c.ep[5] == 5 && c.eo[5] == 0 &&
            c.ep[9] == 9 && c.eo[9] == 0)) {
        return false;
      }
      // Orient remaining edges
      return c.eo[0] == 0 && c.eo[1] == 0 && c.eo[2] == 0 && c.eo[3] == 0 && 
             c.eo[4] == 0 && c.eo[8] == 0 && c.eo[11] == 0;
    }
    // Petrus EO uses F or B to flip edges, combined with U/R to bring bad edges into position
    return _bfs(cube, isSolved, [
      ..._urMoves,
      CubeMove(CubeFace.f, 1), CubeMove(CubeFace.f, -1),
      CubeMove(CubeFace.b, 1), CubeMove(CubeFace.b, -1),
    ], 8) ?? [];
  }

  static List<CubeMove> solveF2L(KociembaCube cube) {
    final moves = <CubeMove>[];
    final working = KociembaCube.clone(cube);

    // Step 4a: Back-Right Slot (Corner 7, Edge 11, and Bottom Edge 4)
    final s4a = _bfs(working, (c) => 
      c.cp[7] == 7 && c.co[7] == 0 && 
      c.ep[11] == 11 && c.eo[11] == 0 &&
      c.ep[4] == 4 && c.eo[4] == 0, 
      _urMoves, 10);
    if (s4a != null) {
      moves.addAll(s4a);
      for (final m in s4a) {
        working.applyMove(m.face, m.turns);
      }
    } else {
      return []; // Failed
    }

    // Step 4b: Front-Right Slot (Corner 4, Edge 8)
    final s4b = _bfs(working, (c) => 
      c.cp[4] == 4 && c.co[4] == 0 && 
      c.ep[8] == 8 && c.eo[8] == 0 &&
      // Must preserve previous
      c.cp[7] == 7 && c.co[7] == 0 && 
      c.ep[11] == 11 && c.eo[11] == 0 &&
      c.ep[4] == 4 && c.eo[4] == 0,
      _urMoves, 10);
    if (s4b != null) {
      moves.addAll(s4b);
    } else {
      return []; // Failed
    }

    return moves;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  static final _uMoves = [CubeMove(CubeFace.u, 1), CubeMove(CubeFace.u, -1), CubeMove(CubeFace.u, 2)];
  static final _urMoves = [..._uMoves, CubeMove(CubeFace.r, 1), CubeMove(CubeFace.r, -1), CubeMove(CubeFace.r, 2)];
  static final _urfMoves = [..._urMoves, CubeMove(CubeFace.f, 1), CubeMove(CubeFace.f, -1), CubeMove(CubeFace.f, 2)];
  static final _allMoves = [..._urfMoves, 
    CubeMove(CubeFace.d, 1), CubeMove(CubeFace.d, -1), CubeMove(CubeFace.d, 2),
    CubeMove(CubeFace.l, 1), CubeMove(CubeFace.l, -1), CubeMove(CubeFace.l, 2),
    CubeMove(CubeFace.b, 1), CubeMove(CubeFace.b, -1), CubeMove(CubeFace.b, 2),
  ];

  static List<CubeMove>? _bfs(KociembaCube start, bool Function(KociembaCube) goal, List<dynamic> moves, int maxDepth) {
    if (goal(start)) {
      return [];
    }
    final queue = Queue<_Node>();
    queue.add(_Node(KociembaCube.clone(start), []));
    final visited = <String>{start.toCompactString()};

    final List<List<CubeMove>> moveSets = moves.map((m) => m is CubeMove ? [m] : m as List<CubeMove>).toList();

    while (queue.isNotEmpty) {
      if (visited.length > 2000000) {
        return null; // Safety limit to prevent OOM
      }
      final node = queue.removeFirst();
      if (node.path.length >= maxDepth) {
        continue;
      }

      for (final ms in moveSets) {
        final next = KociembaCube.clone(node.cube);
        for (final m in ms) {
          next.applyMove(m.face, m.turns);
        }

        if (goal(next)) {
          return [...node.path, ...ms];
        }

        final key = next.toCompactString();
        if (!visited.contains(key)) {
          visited.add(key);
          queue.add(_Node(next, [...node.path, ...ms]));
        }
      }
    }
    return null;
  }
}

class _Node {
  final KociembaCube cube;
  final List<CubeMove> path;
  _Node(this.cube, this.path);
}
