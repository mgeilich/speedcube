import 'package:logging/logging.dart';
import 'dart:collection';
import '../models/cube_state.dart';
import '../models/cube_move.dart';
import '../models/solve_result.dart';
import 'kociemba_coordinates.dart';
import 'kociemba_search.dart';
import 'kociemba_tables.dart';
import 'package:flutter/foundation.dart';

class HeiseSolver {
  static final _log = Logger('HeiseSolver');

  /// Solves the cube using the Heise method.
  static Future<LblSolveResult> solve(CubeState initial, {void Function(String)? onProgress}) async {
    if (initial.isSolved) return const LblSolveResult(steps: []);

    // 1. Initialize tables and analyze orientations
    onProgress?.call("Initializing...");
    await KociembaTables.init();
    
    onProgress?.call("Analyzing orientations...");
    final orientations = generateAll24Rotations();
    
    // Sort orientations by how close they are to a 2x2x2 block at DBL
    orientations.sort((a, b) => scoreHeiseOrientation(initial.applyMoves(b)).compareTo(scoreHeiseOrientation(initial.applyMoves(a))));

    try {
      final startTime = DateTime.now();
      
      // Pass 1: Try the top 4 orientations
      for (int i = 0; i < 4 && i < orientations.length; i++) {
        // Stop if we've spent too much total time
        if (DateTime.now().difference(startTime).inSeconds > 20) break;
        
        final rotation = orientations[i];
        final state = initial.applyMoves(rotation);
        final result = await _solveFromOrientation(state, rotation, onProgress: onProgress);
        if (result != null) return result;
      }

      // Pass 2: Fallback to others
      for (int i = 4; i < orientations.length; i++) {
        if (DateTime.now().difference(startTime).inSeconds > 30) break;
        
        final rotation = orientations[i];
        final state = initial.applyMoves(rotation);
        final result = await _solveFromOrientation(state, rotation, onProgress: onProgress);
        if (result != null) return result;
      }
    } catch (e, stack) {
      _log.severe("Heise solver crashed: $e", e, stack);
    }

    return const LblSolveResult(steps: []);
  }

  static Future<LblSolveResult?> _solveFromOrientation(CubeState state, List<CubeMove> rotation, {void Function(String)? onProgress}) async {
    final steps = <LblStep>[];

    // 0. Initial Orientation
    if (rotation.isNotEmpty) {
      steps.add(LblStep(
        stageName: "Orientation",
        moves: rotation,
        description: "Orient the cube to the best starting position.",
      ));
    }

    var currentState = state;

    // Stage 1: 2x2x2 Block at DBL
    onProgress?.call("Building 2x2x2...");
    final currentK1 = KociembaCube.fromCubeState(currentState);
    final s1Moves = await compute(solve2x2x2Isolate, currentK1.toData());
    if (s1Moves == null) {
      _log.info("Heise Orientation $rotation failed at Stage 1");
      return null;
    }
    if (s1Moves.isNotEmpty) {
      steps.add(LblStep(
        stageName: "2x2x2 Block",
        moves: s1Moves,
        description: "Build a 2x2x2 block in the back-down-left corner.",
      ));
      currentState = currentState.applyMoves(s1Moves);
    }

    // Stage 2: 2x2x3 Block (Expanding Stage 1 to the Front)
    onProgress?.call("Building 2x2x3...");
    final currentK2 = KociembaCube.fromCubeState(currentState);
    final s2Moves = await compute(solve2x2x3Isolate, currentK2.toData());
    if (s2Moves == null) {
      _log.info("Heise Orientation $rotation failed at Stage 2");
      return null;
    }
    if (s2Moves.isNotEmpty) {
      steps.add(LblStep(
        stageName: "2x2x3 Block",
        moves: s2Moves,
        description: "Expand to a 2x2x3 block.",
      ));
      currentState = currentState.applyMoves(s2Moves);
    }

    // Stage 3: Two Squares (Completing F2L-1)
    onProgress?.call("Building Two Squares...");
    final currentK3 = KociembaCube.fromCubeState(currentState);
    final s3Moves = await compute(solveTwoSquaresIsolate, currentK3.toData());
    if (s3Moves == null) {
      _log.info("Heise Orientation $rotation failed at Stage 3");
      return null;
    }
    if (s3Moves.isNotEmpty) {
      steps.add(LblStep(
        stageName: "Two Squares",
        moves: s3Moves,
        description: "Build two more squares to leave only one F2L slot.",
      ));
      currentState = currentState.applyMoves(s3Moves);
    }

    // Stage 4: Edge Orientation
    onProgress?.call("Orienting Edges...");
    final currentK4 = KociembaCube.fromCubeState(currentState);
    final s4Moves = await compute(solveEOIsolate, currentK4.toData());
    if (s4Moves == null) {
      _log.info("Heise Orientation $rotation failed at Stage 4");
      return null;
    }
    if (s4Moves.isNotEmpty) {
      steps.add(LblStep(
        stageName: "Edge Orientation",
        moves: s4Moves,
        description: "Orient the remaining edges.",
      ));
      currentState = currentState.applyMoves(s4Moves);
    }

    // Stage 5: Two Pairs & Edges
    onProgress?.call("Solving Edges & Corners...");
    final s5Moves = await compute(solveEdgesAndTwoCornersIsolate, {
      'state': currentState, 
      'tables': KociembaTables.data,
    });
    if (s5Moves == null) {
      _log.info("Heise Orientation $rotation failed at Stage 5");
      return null;
    }
    if (s5Moves.isNotEmpty) {
      steps.add(LblStep(
        stageName: "Two Pairs & Edges",
        moves: s5Moves,
        description: "Solve all edges and 2 corners, leaving exactly 3 corners for the finish.",
      ));
      currentState = currentState.applyMoves(s5Moves);
    }

    // Stage 6: Commutator Finish
    final s6Result = await compute(solveThreeCornerCommutatorIsolate, {
      'state': currentState, 
      'tables': KociembaTables.data,
    });
    if (s6Result == null) {
      _log.warning("Heise Orientation $rotation Failed at Stage 6: The Commutator Finish");
      return null;
    }
    final s6Moves = s6Result['moves'] as List<CubeMove>;
    final s6IsCommutator = s6Result['isCommutator'] as bool;

    if (s6Moves.isNotEmpty) {
      steps.add(LblStep(
        stageName: s6IsCommutator ? "The Commutator Finish" : "Final Solve (Fallback)",
        moves: s6Moves,
        description: s6IsCommutator 
          ? "Solve the final 3 corners with an [A, B] commutator."
          : "Solve the remaining pieces using a short algorithm.",
      ));
      currentState = currentState.applyMoves(s6Moves);
    }

    if (!currentState.isSolved) return null;

    return LblSolveResult(steps: steps);
  }

  // --- Isolate Wrappers ---

  static List<CubeMove>? solve2x2x2Isolate(List<int> data) {
    try {
      final c = KociembaCube.fromData(data);
      _log.info("  [Isolate] Starting Stage 1 BFS...");
      final result = _bfsFromK(c, (c) => _is2x2x2Solved(c), 8);
      _log.info("  [Isolate] Stage 1 BFS complete. Result: ${result != null ? result.length : 'null'}");
      return result;
    } catch (e, stack) {
      debugPrint("Heise Isolate Error (Stage 1): $e\n$stack");
      rethrow;
    }
  }
  static List<CubeMove>? solve2x2x3Isolate(List<int> data) {
    try {
      final c = KociembaCube.fromData(data);
      _log.info("  [Isolate] Starting Stage 2 BFS (2x2x3)...");
      final result = _bfsFromK(c, (c) => _is2x2x3Solved(c), 10, allowedMoves: _urfMoves);
      _log.info("  [Isolate] Stage 2 BFS complete. Result: ${result != null ? result.length : 'null'}");
      return result;
    } catch (e, stack) {
      debugPrint("Heise Isolate Error (Stage 2): $e\n$stack");
      rethrow;
    }
  }
  static List<CubeMove>? solveEOIsolate(List<int> data) {
    try {
      final c = KociembaCube.fromData(data);
      _log.info("  [Isolate] Starting Stage 4 BFS (EO)...");
      final result = _bfsFromK(c, (c) => _isEOSolved(c), 10, allowedMoves: _urfMoves);
      _log.info("  [Isolate] Stage 4 BFS complete. Result: ${result != null ? result.length : 'null'}");
      return result;
    } catch (e, stack) {
      debugPrint("Heise Isolate Error (Stage 4): $e\n$stack");
      rethrow;
    }
  }
  static List<CubeMove>? solveTwoSquaresIsolate(List<int> data) {
    try {
      final c = KociembaCube.fromData(data);
      _log.info("  [Isolate] Starting Stage 3 BFS (Two Squares)...");
      final result = _bfsFromK(c, (c) => _isTwoSquaresSolved(c), 11, allowedMoves: _urfMoves);
      _log.info("  [Isolate] Stage 3 BFS complete. Result: ${result != null ? result.length : 'null'}");
      return result;
    } catch (e, stack) {
      debugPrint("Heise Isolate Error (Stage 3): $e\n$stack");
      rethrow;
    }
  }
  
  static Future<List<CubeMove>?> solveEdgesAndTwoCornersIsolate(Map<String, dynamic> args) async {
    try {
      KociembaTables.data = args['tables'];
      return _solveEdgesAndTwoCorners(args['state']);
    } catch (e, stack) {
      debugPrint("Heise Isolate Error (Stage 5): $e\n$stack");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> solveThreeCornerCommutatorIsolate(Map<String, dynamic> args) async {
    try {
      KociembaTables.data = args['tables'];
      final startK = KociembaCube.fromCubeState(args['state']);
      if (startK.isSolved) return {'moves': <CubeMove>[], 'isCommutator': true};

      final commutator = _findCommutator(startK);
      if (commutator != null) {
        return {'moves': commutator, 'isCommutator': true};
      }
      // Fallback to Kociemba
      final orientation = _getOrientationToStandard(args['state']);
      final orientedState = args['state'].applyMoves(orientation);
      final search = KociembaSearch(timeLimitMs: 3000);
      final result = await search.solve(orientedState);
      if (result == null) return null;
      
      return {
        'moves': _reorientMoves(result.moves, orientation),
        'isCommutator': false
      };
    } catch (e, stack) {
      debugPrint("Heise Isolate Error (Stage 6): $e\n$stack");
      rethrow;
    }
  }
  
  // --- Stage Solvers ---


  static Future<List<CubeMove>?> _solveEdgesAndTwoCorners(CubeState state) async {
    await KociembaTables.init();
    final orientation = _getOrientationToStandard(state);
    final orientedState = state.applyMoves(orientation);
    
    // 1. Find a full Kociemba solution
    final search = KociembaSearch(timeLimitMs: 3000);
    final res = await search.solve(orientedState);
    if (res == null) return null;

    // 2. Find the EARLIEST state where all edges are solved
    final ck = KociembaCube.fromCubeState(orientedState);
    final partialMoves = <CubeMove>[];
    for (final m in res.moves) {
      ck.applyMove(m.face, m.turns);
      partialMoves.add(m);
      if (ck.isEdgeSolved) break;
    }

    List<CubeMove>? finalMoves;

    if (ck.isEdgeSolved) {
      final unsolved = ck.unsolvedCornerCount;
      if (unsolved == 3) {
        finalMoves = partialMoves;
      } else if (unsolved == 0) {
        // Already solved! "Back off" by applying a corner commutator.
        final candidates = _generateCommutatorCandidates();
        for (final a in candidates) {
          final aPrime = a.reversed.map((m) => CubeMove(m.face, -m.turns)).toList();
          for (final b in candidates) {
            if (a[0].face == b[0].face) continue;
            final bPrime = b.reversed.map((m) => CubeMove(m.face, -m.turns)).toList();
            final comm = [...a, ...b, ...aPrime, ...bPrime];
            final testK = KociembaCube(); // Starts solved
            for (final m in comm) { testK.applyMove(m.face, m.turns); }
            if (testK.isEdgeSolved && testK.unsolvedCornerCount == 3) {
               finalMoves = [...partialMoves, ...comm];
               break;
            }
          }
          if (finalMoves != null) break;
        }
      } else {
        // Try to reach exactly 3 using a commutator.
        final candidates = _generateCommutatorCandidates();
        for (final c in candidates) {
          final testK = KociembaCube.clone(ck);
          for (final m in c) { testK.applyMove(m.face, m.turns); }
          if (testK.isEdgeSolved && testK.unsolvedCornerCount == 3) {
            finalMoves = [...partialMoves, ...c];
            break;
          }
        }
      }
    }

    // Fallback: just use the full solution
    finalMoves ??= res.moves;

    // Directify to avoid "solve-then-break" intermediate states
    final directMoves = await _directify(finalMoves);
    return _reorientMoves(directMoves, orientation);
  }


  static List<CubeMove>? _findCommutator(KociembaCube start) {
    if (start.isSolved) return [];
    final candidates = _generateCommutatorCandidates();

    for (final a in candidates) {
      final aPrime = a.reversed.map((m) => CubeMove(m.face, -m.turns)).toList();
      for (final b in candidates) {
        if (a[0].face == b[0].face) continue;
        final bPrime = b.reversed.map((m) => CubeMove(m.face, -m.turns)).toList();
        final testMoves = [...a, ...b, ...aPrime, ...bPrime];
        final next = KociembaCube.clone(start);
        for (final m in testMoves) { next.applyMove(m.face, m.turns); }
        if (next.isSolved) return testMoves;
      }
    }
    
    // Try with setup moves S [A, B] S'
    final singleMoves = _generateSingleMoves();
    for (final s in singleMoves) {
      final sPrime = s.reversed.map((m) => CubeMove(m.face, -m.turns)).toList();
      final afterS = KociembaCube.clone(start);
      for (final m in s) { afterS.applyMove(m.face, m.turns); }
      
      for (final a in candidates) {
        final aPrime = a.reversed.map((m) => CubeMove(m.face, -m.turns)).toList();
        for (final b in candidates) {
          if (a[0].face == b[0].face) continue;
          final bPrime = b.reversed.map((m) => CubeMove(m.face, -m.turns)).toList();
          final comm = [...a, ...b, ...aPrime, ...bPrime];
          final next = KociembaCube.clone(afterS);
          for (final m in comm) { next.applyMove(m.face, m.turns); }
          if (next.isSolved) return [...s, ...comm, ...sPrime];
        }
      }
    }

    // Try depth-2 setup moves if still not found
    for (final f1 in CubeFace.physicalFaces) {
      for (final t1 in [1, -1, 2]) {
        for (final f2 in CubeFace.physicalFaces) {
          if (f1.index ~/ 2 == f2.index ~/ 2) continue; // Same axis
          for (final t2 in [1, -1, 2]) {
            final s = [CubeMove(f1, t1), CubeMove(f2, t2)];
            final sPrime = s.reversed.map((m) => CubeMove(m.face, -m.turns)).toList();
            final afterS = KociembaCube.clone(start);
            for (final m in s) { afterS.applyMove(m.face, m.turns); }

            for (final a in candidates) {
              final aPrime = a.reversed.map((m) => CubeMove(m.face, -m.turns)).toList();
              for (final b in candidates) {
                if (a[0].face == b[0].face) continue;
                final bPrime = b.reversed.map((m) => CubeMove(m.face, -m.turns)).toList();
                final comm = [...a, ...b, ...aPrime, ...bPrime];
                final next = KociembaCube.clone(afterS);
                for (final m in comm) { next.applyMove(m.face, m.turns); }
                if (next.isSolved) return [...s, ...comm, ...sPrime];
              }
            }
          }
        }
      }
    }
    return null;
  }

  static List<List<CubeMove>> _generateSingleMoves() {
    final moves = <List<CubeMove>>[];
    for (final f in CubeFace.physicalFaces) {
      for (final t in [1, -1, 2]) {
        moves.add([CubeMove(f, t)]);
      }
    }
    return moves;
  }

  static List<List<CubeMove>> _generateCommutatorCandidates() {
    final singleMoves = _generateSingleMoves();
    final conjugates = <List<CubeMove>>[];
    for (final f1 in CubeFace.physicalFaces) {
      for (final t1 in [1, -1]) {
        for (final f2 in CubeFace.physicalFaces) {
          if (f1.index ~/ 2 == f2.index ~/ 2) continue;
          for (final t2 in [1, -1, 2]) {
            conjugates.add([CubeMove(f1, t1), CubeMove(f2, t2), CubeMove(f1, -t1)]);
          }
        }
      }
    }
    
    final all = [...singleMoves, ...conjugates];
    
    // We only want commutators [A, B] that preserve edges.
    // However, generating all [A, B] and checking isEdgeSolved is better.
    return all; 
  }
  
  // Actually, let's filter them in _findCommutator instead to be more flexible,
  // but for the "forcing" logic, we definitely want edge-preserving ones.




  // --- Goal Checks ---

  static bool _is2x2x2Solved(KociembaCube c) {
    return c.cp[6] == 6 && c.co[6] == 0 &&
           c.ep[6] == 6 && c.eo[6] == 0 &&
           c.ep[7] == 7 && c.eo[7] == 0 &&
           c.ep[10] == 10 && c.eo[10] == 0;
  }

  static bool _is2x2x3Solved(KociembaCube c) {
    if (!_is2x2x2Solved(c)) return false;
    return c.ep[9] == 9 && c.eo[9] == 0 &&
           c.ep[5] == 5 && c.eo[5] == 0 &&
           c.cp[5] == 5 && c.co[5] == 0;
  }

  static bool _isTwoSquaresSolved(KociembaCube c) {
    if (!_is2x2x3Solved(c)) return false;
    // Solve everything except FR slot and Last Layer.
    final requiredEdges = [5, 6, 7, 9, 10, 11]; // DF, DL, DB, FL, BL, BR
    final requiredCorners = [5, 6, 7]; // DFL, DBL, DBR
    for (final e in requiredEdges) {
      if (c.ep[e] != e || c.eo[e] != 0) return false;
    }
    for (final co in requiredCorners) {
      if (c.cp[co] != co || c.co[co] != 0) return false;
    }
    return true;
  }

  static bool _isEOSolved(KociembaCube c) {
    if (!_isTwoSquaresSolved(c)) return false;
    for (int i = 0; i < 12; i++) {
      if (c.eo[i] != 0) return false;
    }
    return true;
  }

  // --- Utilities ---

  static List<CubeMove>? _bfsFromK(KociembaCube start, bool Function(KociembaCube) goal, int maxDepth, {List<CubeMove>? allowedMoves}) {
    if (goal(start)) return [];
    
    final startTime = DateTime.now();
    final queue = Queue<_SearchNode>();
    final startHash = start.hashCode;
    queue.add(_SearchNode(start, [], startHash));
    final visited = {startHash};
    
    final moves = allowedMoves ?? CubeMove.physicalMoves;
    int nodeCount = 0;
    
    while (queue.isNotEmpty) {
      nodeCount++;
      if (nodeCount % 1000 == 0) {
        if (nodeCount > 400000) {
          _log.info("  [BFS] Pruned at 400k nodes");
          return null;
        }
        if (DateTime.now().difference(startTime).inMilliseconds > 4000) {
          _log.info("  [BFS] Time limit (4s) exceeded at $nodeCount nodes");
          return null;
        }
      }
      
      final node = queue.removeFirst();
      if (node.path.length >= maxDepth) continue;
      
      for (final move in moves) {
        // Prune same face
        if (node.path.isNotEmpty && node.path.last.face == move.face) continue;
        
        final next = KociembaCube.clone(node.cube);
        next.applyMove(move.face, move.turns);
        
        if (goal(next)) return [...node.path, move];
        
        final nextHash = next.hashCode;
        if (!visited.contains(nextHash)) {
          visited.add(nextHash);
          queue.add(_SearchNode(next, [...node.path, move], nextHash));
        }
      }
    }
    return null;
  }


  static List<CubeMove> _getOrientationToStandard(CubeState state) {
    final orientationMoves = <CubeMove>[];
    final whiteFace = _findCenterFace(state, CubeColor.white);
    if (whiteFace == CubeFace.d) {
      orientationMoves.add(CubeMove.x2);
    } else if (whiteFace == CubeFace.f) {
      orientationMoves.add(CubeMove.x);
    } else if (whiteFace == CubeFace.b) {
      orientationMoves.add(CubeMove.xPrime);
    } else if (whiteFace == CubeFace.l) {
      orientationMoves.add(CubeMove.z);
    } else if (whiteFace == CubeFace.r) {
      orientationMoves.add(CubeMove.zPrime);
    }
    var orientedState = state.applyMoves(orientationMoves);
    final greenFace = _findCenterFace(orientedState, CubeColor.green);
    if (greenFace == CubeFace.b) {
      orientationMoves.add(CubeMove.y2);
    } else if (greenFace == CubeFace.r) {
      orientationMoves.add(CubeMove.y);
    } else if (greenFace == CubeFace.l) {
      orientationMoves.add(CubeMove.yPrime);
    }
    return orientationMoves;
  }

  static CubeFace _findCenterFace(CubeState s, CubeColor c) {
    for (final f in CubeFace.physicalFaces) {
      if (s.getFace(f)[4] == c) return f;
    }
    return CubeFace.u;
  }

  static int scoreHeiseOrientation(CubeState s) {
    int score = 0;
    final c = KociembaCube.fromCubeState(s);
    if (c.cp[6] == 6 && c.co[6] == 0) score += 10;
    if (c.ep[6] == 6 && c.eo[6] == 0) score += 5;
    if (c.ep[7] == 7 && c.eo[7] == 0) score += 5;
    if (c.ep[10] == 10 && c.eo[10] == 0) score += 5;
    return score;
  }

  static List<List<CubeMove>> generateAll24Rotations() {
    final List<List<CubeMove>> res = [];
    final downs = [<CubeMove>[], [CubeMove.x], [CubeMove.x2], [CubeMove.xPrime], [CubeMove.z], [CubeMove.zPrime]];
    for (final d in downs) {
      for (int i = 0; i < 4; i++) {
        final r = List<CubeMove>.from(d);
        if (i == 1) {
          r.add(CubeMove.y);
        } else if (i == 2) {
          r.add(CubeMove.y2);
        } else if (i == 3) {
          r.add(CubeMove.yPrime);
        }
        res.add(r);
      }
    }
    return res;
  }

  static List<CubeMove> _reorientMoves(List<CubeMove> moves, List<CubeMove> orientation) {
    if (orientation.isEmpty) return moves;
    
    // Reverse the orientation to find the mapping from standard to current
    final invOrientation = orientation.reversed.map((m) => m.inverse).toList();
    
    return moves.map((m) {
      final face = _mapFace(m.face, invOrientation);
      return CubeMove(face, m.turns, m.isWide);
    }).toList();
  }

  static CubeFace _mapFace(CubeFace face, List<CubeMove> orientation) {
    // Map a face in standard orientation back to the current physical orientation
    CubeState s = CubeState.solved();
    s = s.applyMoves(orientation);
    final faceColors = s.getFace(face);
    final centerColor = faceColors[4];
    
    if (centerColor == CubeColor.white) return CubeFace.u;
    if (centerColor == CubeColor.yellow) return CubeFace.d;
    if (centerColor == CubeColor.orange) return CubeFace.l;
    if (centerColor == CubeColor.red) return CubeFace.r;
    if (centerColor == CubeColor.green) return CubeFace.f;
    if (centerColor == CubeColor.blue) return CubeFace.b;
    return face;
  }

  /// Returns the shortest move sequence that reaches the same state as the input moves.
  /// This is used to avoid "solve-then-break" paths in the tutorial.
  static Future<List<CubeMove>> _directify(List<CubeMove> moves) async {
    if (moves.isEmpty) return [];
    
    // To find the shortest path to state T = Identity * moves,
    // we solve the state T^-1 to identity.
    // T^-1 = moves^-1(Identity).
    final invMoves = moves.reversed.map((m) => m.inverse).toList();
    final searchState = CubeState.solved().applyMoves(invMoves);
    
    final search = KociembaSearch(timeLimitMs: 2000);
    final res = await search.solve(searchState);
    
    if (res == null) return CubeMove.optimize(moves);
    return res.moves;
  }

  static final _urfMoves = [
    CubeMove.u, CubeMove.uPrime, CubeMove.u2,
    CubeMove.r, CubeMove.rPrime, CubeMove.r2,
    CubeMove.f, CubeMove.fPrime, CubeMove.f2,
  ];

}

class _SearchNode {
  final KociembaCube cube;
  final List<CubeMove> path;
  final int hash;
  _SearchNode(this.cube, this.path, this.hash);
}
