import '../models/cube_state.dart';
import '../models/cube_move.dart';
import '../models/solve_result.dart';
import 'kociemba_coordinates.dart';
import 'kociemba_search.dart';
import 'dart:collection';
import 'kociemba_tables.dart';
import 'package:flutter/foundation.dart';

class PetrusStep extends LblStep {
  const PetrusStep({
    required super.stageName,
    required super.moves,
    super.algorithmName,
    required super.description,
  });
}

class PetrusSolver {
  /// Entry point for the Petrus solver.
  static Future<LblSolveResult> solve(CubeState initial, {void Function(String)? onProgress}) async {
    if (initial.isSolved) return const LblSolveResult(steps: []);
    
    // 1. Analyze all 24 orientations and pick the one with the best 2x2x2 block
    onProgress?.call("Analyzing orientations...");
    final orientations = _generateAll24Rotations();
    
    // Sort orientations by how close they are to a 2x2x2 block
    orientations.sort((a, b) => _scorePetrusOrientation(initial.applyMoves(b)).compareTo(_scorePetrusOrientation(initial.applyMoves(a))));

    // Pass 1: Try the top 4 orientations
    for (int i = 0; i < 4 && i < orientations.length; i++) {
      final rotation = orientations[i];
      final state = initial.applyMoves(rotation);
      final result = await _solveFromOrientation(state, rotation, onProgress: onProgress);
      if (result != null) return result;
    }

    // Pass 2: Fallback
    for (int i = 4; i < orientations.length; i++) {
      final rotation = orientations[i];
      final state = initial.applyMoves(rotation);
      final result = await _solveFromOrientation(state, rotation, onProgress: onProgress);
      if (result != null) return result;
    }

    return LblSolveResult(steps: []);
  }

  static Future<LblSolveResult?> _solveFromOrientation(CubeState state, List<CubeMove> rotation, {void Function(String)? onProgress}) async {
    final steps = <LblStep>[];

    // 0. Initial Orientation
    if (rotation.isNotEmpty) {
      steps.add(LblStep(
        stageName: "Orientation",
        moves: rotation,
        description: "Orienting the cube to the best starting position.",
      ));
    }

    KociembaCube currentCube = KociembaCube.fromCubeState(state);

    // Stage 1: 2x2x2 Block
    onProgress?.call("Solving 2x2x2 Block...");
    final s1Moves = await compute(_solve2x2x2Isolate, {'cube': currentCube, 'tables': KociembaTables.data});
    if (s1Moves == null) return null;
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
    onProgress?.call("Expanding 2x2x3...");
    final s2Moves = await compute(_solve2x2x3Isolate, {'cube': currentCube, 'tables': KociembaTables.data});
    if (s2Moves == null) return null;
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
    onProgress?.call("Orienting Edges...");
    final s3Moves = await compute(_solveEOIsolate, {'cube': currentCube, 'tables': KociembaTables.data});
    if (s3Moves == null) return null;
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

    // Stage 4: F2L Finish
    onProgress?.call("Finishing F2L...");
    final s4Moves = await compute(_solveF2LIsolate, {'cube': currentCube, 'tables': KociembaTables.data});
    if (s4Moves == null) return null;
    if (s4Moves.isNotEmpty) {
      steps.add(PetrusStep(
        stageName: "F2L Finish",
        moves: s4Moves,
        description: "Complete the remaining F2L slots.",
      ));
      for (final m in s4Moves) {
        currentCube.applyMove(m.face, m.turns);
      }
    }

    // Stage 5: Last Layer
    onProgress?.call("Solving Last Layer...");
    // Note: 'state' is already rotated. Build finalState by applying
    // only the non-orientation steps (all steps except the first Orientation step).
    final blockMoves = steps.skip(rotation.isEmpty ? 0 : 1).expand((s) => s.moves).toList();
    final finalState = state.applyMoves(blockMoves);
    final s5Moves = await solveLL(finalState);
    if (s5Moves.isNotEmpty) {
      steps.add(LblStep(
        stageName: "Last Layer",
        moves: s5Moves,
        description: "Solve the final layer using orientation and permutation.",
      ));
    } else if (!finalState.isSolved) {
      return null;
    }

    return LblSolveResult(steps: steps);
  }

  // Scoring for Petrus
  static int _scorePetrusOrientation(CubeState s) {
    // Petrus also starts with a 2x2x2 block at DBL
    int score = 0;
    final c = KociembaCube.fromCubeState(s);
    
    // Back-Down-Left 2x2x2 block
    if (c.cp[6] == 6 && c.co[6] == 0) score += 10; // Corner
    if (c.ep[6] == 6 && c.eo[6] == 0) score += 5;  // DL
    if (c.ep[7] == 7 && c.eo[7] == 0) score += 5;  // DB
    if (c.ep[10] == 10 && c.eo[10] == 0) score += 5; // BL
    
    return score;
  }

  // Isolate wrappers
  static List<CubeMove>? _solve2x2x2Isolate(Map<String, dynamic> args) {
    KociembaTables.data = args['tables'];
    return solve2x2x2(args['cube']);
  }
  static List<CubeMove>? _solve2x2x3Isolate(Map<String, dynamic> args) {
    KociembaTables.data = args['tables'];
    return solve2x2x3(args['cube']);
  }
  static List<CubeMove>? _solveEOIsolate(Map<String, dynamic> args) {
    KociembaTables.data = args['tables'];
    return solveEO(args['cube']);
  }
  static List<CubeMove>? _solveF2LIsolate(Map<String, dynamic> args) {
    KociembaTables.data = args['tables'];
    return solveF2L(args['cube']);
  }

  static Future<List<CubeMove>> solveLL(CubeState state) async {
    if (state.isSolved) return [];
    await KociembaTables.init();
    
    // 1. Orient the cube to standard (White Top, Green Front)
    final orientation = _getOrientationToStandard(state);
    final orientedState = state.applyMoves(orientation);

    // 2. Solve the Last Layer using Kociemba search
    final search = KociembaSearch(timeLimitMs: 2000);
    final result = await search.solve(orientedState);
    if (result == null) return [];
    
    // 3. Return the orientation moves followed by the solution moves
    return [...orientation, ...result.moves];
  }

  static List<CubeMove> _getOrientationToStandard(CubeState state) {
    final orientationMoves = <CubeMove>[];
    final whiteFace = _findCenterFace(state, CubeColor.white);
    if (whiteFace == CubeFace.d) { orientationMoves.add(CubeMove.x2); }
    else if (whiteFace == CubeFace.f) { orientationMoves.add(CubeMove.x); }
    else if (whiteFace == CubeFace.b) { orientationMoves.add(CubeMove.xPrime); }
    else if (whiteFace == CubeFace.l) { orientationMoves.add(CubeMove.z); }
    else if (whiteFace == CubeFace.r) { orientationMoves.add(CubeMove.zPrime); }
    
    var orientedState = state.applyMoves(orientationMoves);
    final greenFace = _findCenterFace(orientedState, CubeColor.green);
    if (greenFace == CubeFace.b) { orientationMoves.add(CubeMove.y2); }
    else if (greenFace == CubeFace.r) { orientationMoves.add(CubeMove.y); }
    else if (greenFace == CubeFace.l) { orientationMoves.add(CubeMove.yPrime); }
    
    return orientationMoves;
  }

  static CubeFace _findCenterFace(CubeState s, CubeColor c) {
    for (final f in CubeFace.physicalFaces) {
      if (s.getFace(f)[4] == c) return f;
    }
    return CubeFace.u;
  }

  static List<List<CubeMove>> _generateAll24Rotations() {
    final List<List<CubeMove>> res = [];
    final downs = [<CubeMove>[], [CubeMove.x], [CubeMove.x2], [CubeMove.xPrime], [CubeMove.z], [CubeMove.zPrime]];
    for (final d in downs) {
      for (int i = 0; i < 4; i++) {
        final r = List<CubeMove>.from(d);
        if (i == 1) { r.add(CubeMove.y); }
        else if (i == 2) { r.add(CubeMove.y2); }
        else if (i == 3) { r.add(CubeMove.yPrime); }
        res.add(r);
      }
    }
    return res;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STAGES
  // ─────────────────────────────────────────────────────────────────────────

  static bool is2x2x2Solved(KociembaCube c) =>
      c.cp[6] == 6 && c.co[6] == 0 && 
      c.ep[6] == 6 && c.eo[6] == 0 &&
      c.ep[7] == 7 && c.eo[7] == 0 &&
      c.ep[10] == 10 && c.eo[10] == 0;

  static bool is2x2x3Solved(KociembaCube c) {
    if (!is2x2x2Solved(c)) return false;
    return c.cp[5] == 5 && c.co[5] == 0 && c.ep[5] == 5 && c.eo[5] == 0 && c.ep[9] == 9 && c.eo[9] == 0;
  }

  static List<CubeMove>? solve2x2x2(KociembaCube cube) {
    final moves = <CubeMove>[];
    final working = KociembaCube.clone(cube);

    // Step 1a: Solve dBL corner and dL, dB edges
    final s1a = _bfs(working, (c) => 
      c.cp[6] == 6 && c.co[6] == 0 && 
      c.ep[6] == 6 && c.eo[6] == 0 &&
      c.ep[7] == 7 && c.eo[7] == 0, 
      _allMoves, 8);
    if (s1a != null) {
      moves.addAll(s1a);
      for (final m in s1a) {
        working.applyMove(m.face, m.turns);
      }
    } else {
      return null; // Failed
    }

    // Step 1b: Solve bL edge while preserving 1a
    final s1b = _bfs(working, (c) => 
      c.cp[6] == 6 && c.co[6] == 0 && 
      c.ep[6] == 6 && c.eo[6] == 0 &&
      c.ep[7] == 7 && c.eo[7] == 0 &&
      c.ep[10] == 10 && c.eo[10] == 0,
      _allMoves, 8);
    if (s1b != null) {
      moves.addAll(s1b);
    } else {
      return null; // Failed
    }

    return moves;
  }

  static List<CubeMove>? solve2x2x3(KociembaCube cube) {
    bool isSolved(KociembaCube c) {
      if (!(c.cp[6] == 6 && c.co[6] == 0 && c.ep[6] == 6 && c.eo[6] == 0 &&
            c.ep[7] == 7 && c.eo[7] == 0 && c.ep[10] == 10 && c.eo[10] == 0)) {
        return false;
      }
      return c.cp[5] == 5 && c.co[5] == 0 && c.ep[5] == 5 && c.eo[5] == 0 && c.ep[9] == 9 && c.eo[9] == 0;
    }
    // Only U, R, F preserve the dBL 2x2x2
    return _bfs(cube, isSolved, _urfMoves, 10);
  }

  static List<CubeMove>? solveEO(KociembaCube cube) {
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
    ], 8);
  }

  static List<CubeMove>? solveF2L(KociembaCube cube) {
    final moves = <CubeMove>[];
    final working = KociembaCube.clone(cube);

    // Step 4a: Back-Right Slot (Corner 7, Edge 11, and Bottom Edge 4)
    final s4a = _bfs(working, (c) => 
      c.cp[7] == 7 && c.co[7] == 0 && 
      c.ep[11] == 11 && c.eo[11] == 0 &&
      c.ep[4] == 4 && c.eo[4] == 0, 
      _urMoves, 11);
    if (s4a != null) {
      moves.addAll(s4a);
      for (final m in s4a) {
        working.applyMove(m.face, m.turns);
      }
    } else {
      return null; // Failed
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
      return null; // Failed
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
    final visited = <int>{start.hashCode};

    final List<List<CubeMove>> moveSets = moves.map((m) => m is CubeMove ? [m] : m as List<CubeMove>).toList();
    int nodeCount = 0;

    while (queue.isNotEmpty) {
      if (nodeCount++ > 2000000) {
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

        if (!visited.contains(next.hashCode)) {
          visited.add(next.hashCode);
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
