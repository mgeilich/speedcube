import '../models/cube_state.dart';
import '../models/cube_move.dart';
import '../models/alg_library.dart';
import '../models/solve_result.dart';
import 'kociemba_tables.dart';
import 'kociemba_coordinates.dart';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// A solver that implements the ZZ method (EOLine, ZZ-F2L, LL).
class ZzSolver {
  
  /// Solve the cube using the ZZ method.
  static Future<LblSolveResult?> solve(CubeState initial, {void Function(String)? onProgress}) async {
    if (initial.isSolved) return const LblSolveResult(steps: []);

    // 1. Orientation Scoring
    final orientations = _generateAll24Rotations();
    orientations.sort((a, b) => _scoreZzOrientation(initial.applyMoves(b)).compareTo(_scoreZzOrientation(initial.applyMoves(a))));
    
    onProgress?.call("Analyzing orientations...");

    // Pass 1: Try top 12 orientations with generous budget
    for (int i = 0; i < 12 && i < orientations.length; i++) {
        final rotation = orientations[i];
        final oriented = initial.applyMoves(rotation);
        final result = await _solveFromOrientation(oriented, rotation, onProgress: onProgress);
        if (result != null) return result;
    }

    return null;
  }

  static int _scoreZzOrientation(CubeState s) {
    int score = 0;
    final cube = KociembaCube.fromCubeState(s);
    
    // Count oriented edges (crucial for EOLine)
    for (int i = 0; i < 12; i++) {
      if (cube.eo[i] == 0) score += 10;
    }
    
    // Favor cases where DF or DB are already close to home
    if (cube.ep[5] == 5 && cube.eo[5] == 0) score += 50;
    if (cube.ep[7] == 7 && cube.eo[7] == 0) score += 50;

    // Favor "True ZZ" orientations (White or Yellow on bottom)
    final cD = s.getFace(CubeFace.d)[4];
    if (cD == CubeColor.white || cD == CubeColor.yellow) score += 30;

    return score;
  }


  static Future<LblSolveResult?> _solveFromOrientation(CubeState oriented, List<CubeMove> preMoves, {void Function(String)? onProgress}) async {
    final steps = <LblStep>[];
    if (preMoves.isNotEmpty) {
      steps.add(LblStep(
        stageName: 'Orientation',
        moves: preMoves,
        description: 'Orient the cube for ZZ.',
      ));
    }

    var s = oriented;

    // Stage 1a: EO (Edge Orientation)
    onProgress?.call("Orienting Edges...");
    final eoMoves = await compute(_findEoIsolate, {'state': s, 'tables': KociembaTables.data});
    if (eoMoves == null) return null;
    if (eoMoves.isNotEmpty) {
      steps.add(LblStep(
        stageName: 'Stage 1a: EO',
        moves: eoMoves,
        description: 'Orienting all 12 edges.',
      ));
      s = s.applyMoves(eoMoves);
    }

    // Stage 1b: Line (DF/DB)
    onProgress?.call("Solving Line...");
    final lineMoves = await compute(_findLineIsolate, {'state': s, 'tables': KociembaTables.data});
    if (lineMoves == null) return null;
    if (lineMoves.isNotEmpty) {
      steps.add(LblStep(
        stageName: 'Stage 1b: Line',
        moves: lineMoves,
        description: 'Placing the DF and DB edges.',
      ));
      s = s.applyMoves(lineMoves);
    }

    // Stage 2: Left Block
    onProgress?.call("Solving Left Block...");
    final lbSteps = await compute(_solveLeftBlockIsolate, {'state': s, 'tables': KociembaTables.data});
    if (lbSteps == null) return null;
    steps.addAll(lbSteps);
    s = s.applyMoves(lbSteps.expand((st) => st.moves).toList());

    // Stage 3: Right Block
    onProgress?.call("Solving Right Block...");
    final rbSteps = await compute(_solveRightBlockIsolate, {'state': s, 'tables': KociembaTables.data});
    if (rbSteps == null) return null;
    steps.addAll(rbSteps);
    s = s.applyMoves(rbSteps.expand((st) => st.moves).toList());

    // Stage 4: Last Layer
    onProgress?.call("Solving Last Layer...");
    final llSteps = _solveLL(s);
    if (llSteps == null) return null;
    steps.addAll(llSteps);

    return LblSolveResult(steps: steps);
  }

  // Isolate wrappers
  static List<CubeMove>? _findEoIsolate(Map<String, dynamic> args) {
    KociembaTables.data = args['tables'];
    return _findEO(args['state']);
  }
  static List<CubeMove>? _findLineIsolate(Map<String, dynamic> args) {
    KociembaTables.data = args['tables'];
    return _findLine(args['state']);
  }
  static List<LblStep>? _solveLeftBlockIsolate(Map<String, dynamic> args) {
    KociembaTables.data = args['tables'];
    return _solveBlock(args['state'], isLeft: true);
  }
  static List<LblStep>? _solveRightBlockIsolate(Map<String, dynamic> args) {
    KociembaTables.data = args['tables'];
    return _solveBlock(args['state'], isLeft: false, preserveOtherBlock: true);
  }



  /// Finds moves to orient all edges.
  static List<CubeMove>? _findEO(CubeState s) {
    final start = KociembaCube.fromCubeState(s);
    if (start.eo.every((e) => e == 0)) return [];

    // Simple BFS for EO (only 2048 states)
    final queue = Queue<KociembaCube>();
    queue.add(start);
    final visited = <int, List<CubeMove>>{start.flip: []};

    while (queue.isNotEmpty) {
      final curr = queue.removeFirst();
      final path = visited[curr.flip]!;
      if (path.length >= 8) continue;

      for (int face = 0; face < 6; face++) {
        if (path.isNotEmpty && path.last.face == CubeFace.values[face]) continue;
        for (int turns in [1, -1, 2]) {
          final next = KociembaCube.clone(curr);
          next.applyMove(CubeFace.values[face], turns);
          if (next.eo.every((e) => e == 0)) return [...path, CubeMove(CubeFace.values[face], turns)];
          
          if (!visited.containsKey(next.flip)) {
            visited[next.flip] = [...path, CubeMove(CubeFace.values[face], turns)];
            queue.add(next);
          }
        }
      }
    }
    return null;
  }

  /// Finds moves to solve DF and DB while preserving EO.
  static List<CubeMove>? _findLine(CubeState s) {
    final start = KociembaCube.fromCubeState(s);
    if (_isLineSolved(start)) return [];

    // Restricted move set to preserve EO: <U, D, R, L, F2, B2>
    final lineMoves = [
      CubeMove(CubeFace.u, 1), CubeMove(CubeFace.u, -1), CubeMove(CubeFace.u, 2),
      CubeMove(CubeFace.d, 1), CubeMove(CubeFace.d, -1), CubeMove(CubeFace.d, 2),
      CubeMove(CubeFace.r, 1), CubeMove(CubeFace.r, -1), CubeMove(CubeFace.r, 2),
      CubeMove(CubeFace.l, 1), CubeMove(CubeFace.l, -1), CubeMove(CubeFace.l, 2),
      CubeMove(CubeFace.f, 2), CubeMove(CubeFace.b, 2),
    ];

    final queue = Queue<_KNode>();
    queue.add(_KNode(start, []));
    final visited = {start.hashCode};
    int nodeCount = 0;

    while (queue.isNotEmpty) {
      if (nodeCount++ > 1000000) return null;

      final node = queue.removeFirst();
      if (node.path.length >= 14) continue; 

      for (final move in lineMoves) {
        if (node.path.isNotEmpty && node.path.last.face == move.face) continue;

        final next = KociembaCube.clone(node.cube);
        next.applyMove(move.face, move.turns);
        
        if (_isLineSolved(next)) {
          return [...node.path, move];
        }
        final h = next.hashCode;
        if (!visited.contains(h)) {
          visited.add(h);
          queue.add(_KNode(next, [...node.path, move]));
        }
      }
    }
    return null;
  }

  static bool _isLineSolved(KociembaCube c) {
    // DF is 5, DB is 7.
    return c.ep[5] == 5 && c.eo[5] == 0 &&
           c.ep[7] == 7 && c.eo[7] == 0;
  }

  // --- STAGE 2 & 3: Block Building ---

  static List<LblStep>? _solveBlock(CubeState initial, {required bool isLeft, bool preserveOtherBlock = false}) {
    final steps = <LblStep>[];
    var current = initial;
    var currentK = KociembaCube.fromCubeState(current);
    
    final stageName = isLeft ? 'Stage 2: Left Block' : 'Stage 3: Right Block';

    // ZZ Left block pieces (coordinate indices after EO+Line with standard orientation):
    //   Corner DFL = 5, Corner DBL = 6
    //   Edges: DF=5(Line), DL=6, FL=9, DB=7(Line), BL=10
    // ZZ Right block pieces:
    //   Corner DFR = 4, Corner DBR = 7
    //   Edges: DR=4, FR=8, BR=11
    // The Line (DF=5, DB=7) is already solved; we only need to add the other pieces.

    final kTasks = isLeft ? [
      _KTask('DL Edge',     (k) => k.ep[6] == 6 && k.eo[6] == 0),
      _KTask('Front Square',(k) => k.ep[6] == 6 && k.eo[6] == 0 &&
                                   k.ep[9] == 9 && k.eo[9] == 0 &&
                                   k.cp[5] == 5 && k.co[5] == 0),
      _KTask('Back Square', (k) => k.ep[6] == 6 && k.eo[6] == 0 &&
                                   k.ep[9] == 9 && k.eo[9] == 0 &&
                                   k.cp[5] == 5 && k.co[5] == 0 &&
                                   k.ep[10] == 10 && k.eo[10] == 0 &&
                                   k.cp[6] == 6 && k.co[6] == 0),
    ] : [
      _KTask('DR Edge',     (k) => k.ep[4] == 4 && k.eo[4] == 0),
      _KTask('Front Square',(k) => k.ep[4] == 4 && k.eo[4] == 0 &&
                                   k.ep[8] == 8 && k.eo[8] == 0 &&
                                   k.cp[4] == 4 && k.co[4] == 0),
      _KTask('Back Square', (k) => k.ep[4] == 4 && k.eo[4] == 0 &&
                                   k.ep[8] == 8 && k.eo[8] == 0 &&
                                   k.cp[4] == 4 && k.co[4] == 0 &&
                                   k.ep[11] == 11 && k.eo[11] == 0 &&
                                   k.cp[7] == 7 && k.co[7] == 0),
    ];

    // Invariant: Line (ep[5], ep[7]) and EO must stay solved throughout
    // Additional invariant for Right block: preserve the Left block
    bool leftBlockSolved(KociembaCube k) =>
        k.ep[6] == 6 && k.eo[6] == 0 &&
        k.ep[9] == 9 && k.eo[9] == 0 &&
        k.ep[10] == 10 && k.eo[10] == 0 &&
        k.cp[5] == 5 && k.co[5] == 0 &&
        k.cp[6] == 6 && k.co[6] == 0;

    final solvedKTasks = <bool Function(KociembaCube)>[];
    if (preserveOtherBlock) {
      solvedKTasks.add(leftBlockSolved);
    }

    for (final task in kTasks) {
      if (task.isSolved(currentK)) {
        solvedKTasks.add(task.isSolved);
        continue;
      }

      final movesResult = _searchForPieceK(currentK, stageName, task.name, task.isSolved, solvedKTasks);
      if (movesResult == null) return null;

      steps.add(LblStep(
        stageName: stageName,
        moves: movesResult,
        description: 'Solving the ${task.name}.',
      ));
      current = current.applyMoves(movesResult);
      currentK = KociembaCube.fromCubeState(current);
      solvedKTasks.add(task.isSolved);
    }

    return steps;
  }

  static List<CubeMove>? _searchForPieceK(KociembaCube current, String stage, String pieceName, bool Function(KociembaCube) isSolved, List<bool Function(KociembaCube)> mustStaySolved) {
    final queue = Queue<_KNode>();
    queue.add(_KNode(current, []));
    final visited = {current.hashCode};
    int nodeCount = 0;
    const maxNodes = 1000000;
    
    final moves = [
      CubeMove(CubeFace.u, 1), CubeMove(CubeFace.u, -1), CubeMove(CubeFace.u, 2),
      CubeMove(CubeFace.l, 1), CubeMove(CubeFace.l, -1), CubeMove(CubeFace.l, 2),
      CubeMove(CubeFace.r, 1), CubeMove(CubeFace.r, -1), CubeMove(CubeFace.r, 2),
    ];

    while (queue.isNotEmpty) {
      if (nodeCount++ > maxNodes) return null;
      final node = queue.removeFirst();
      
      if (node.path.length >= 10) continue;
      
      for (final move in moves) {
        if (node.path.isNotEmpty && node.path.last.face == move.face) continue;
        
        final next = KociembaCube.clone(node.cube);
        next.applyMove(move.face, move.turns);

        if (isSolved(next) && _isEOCompleteK(next) && _isLineSolvedK(next)) {
          bool preservesAll = true;
          for (final check in mustStaySolved) {
            if (!check(next)) {
              preservesAll = false;
              break;
            }
          }
          
          if (preservesAll) {
            return [...node.path, move];
          }
        }
        final h = next.hashCode;
        if (!visited.contains(h)) {
          visited.add(h);
          queue.add(_KNode(next, [...node.path, move]));
        }
      }
    }
    return null;
  }

  static bool _isEOCompleteK(KociembaCube k) {
    return k.eo.every((e) => e == 0);
  }

  static bool _isLineSolvedK(KociembaCube k) {
    // DF (5) and DB (7) edges
    return k.ep[5] == 5 && k.eo[5] == 0 && k.ep[7] == 7 && k.eo[7] == 0;
  }

  // --- STAGE 4: Last Layer ---

  static List<LblStep>? _solveLL(CubeState s) {
    final steps = <LblStep>[];
    var current = s;

    // 1. Orient Corners (OCLL)
    // Since edges are oriented, we can use the OLL "Cross" cases
    final yellow = current.getFace(CubeFace.u)[4];
    bool isOllOriented(CubeState cs) => cs.getFace(CubeFace.u).every((stk) => stk == yellow);

    if (!isOllOriented(current)) {
      AlgCase? matched; int uTurns = 0;
      final crossOllCases = AlgLibrary.oll.where((c) => c.subcategory == 'Cross').toList();
      
      outer: for (int i=0; i<4; i++) {
        final setup = i == 0 ? <CubeMove>[] : [CubeMove(CubeFace.u, i)];
        final testS = current.applyMoves(setup);
        for (final c in crossOllCases) {
          if (isOllOriented(testS.applyMoves(c.algorithmMoves))) {
            matched = c; uTurns = i; break outer;
          }
        }
      }

      if (matched != null) {
        final setup = uTurns == 0 ? <CubeMove>[] : [CubeMove(CubeFace.u, uTurns)];
        steps.add(LblStep(
          stageName: 'Stage 4: Last Layer',
          algorithmName: 'OCLL: ${matched.name}',
          moves: [...setup, ...matched.algorithmMoves],
          description: 'Orienting the top corners.',
        ));
        current = current.applyMoves(steps.last.moves);
      }
    }

    // 2. Permute All (PLL)
    // Same logic as CFOP/Beginner
    bool isSideSolved(CubeState cs) {
      for (final f in [CubeFace.f, CubeFace.r, CubeFace.b, CubeFace.l]) {
        final stickers = cs.getFace(f);
        if (stickers[0] != stickers[4] || stickers[1] != stickers[4] || stickers[2] != stickers[4]) return false;
      }
      return true;
    }

    if (!isSideSolved(current) || !current.isSolved) {
      AlgCase? matched; int uTurns = 0; int finalAlign = 0;
      outer: for (int i=0; i<4; i++) {
        final setup = i == 0 ? <CubeMove>[] : [CubeMove(CubeFace.u, i)];
        final testS = current.applyMoves(setup);
        for (final c in AlgLibrary.pll) {
          final nextS = testS.applyMoves(c.algorithmMoves);
          for (int k=0; k<4; k++) {
            final align = k == 0 ? <CubeMove>[] : [CubeMove(CubeFace.u, k)];
            if (nextS.applyMoves(align).isSolved) {
              matched = c; uTurns = i; finalAlign = k; break outer;
            }
          }
        }
      }

      if (matched != null) {
        final setup = uTurns == 0 ? <CubeMove>[] : [CubeMove(CubeFace.u, uTurns)];
        final align = finalAlign == 0 ? <CubeMove>[] : [CubeMove(CubeFace.u, finalAlign)];
        final pllMoves = [...setup, ...matched.algorithmMoves, ...align];
        steps.add(LblStep(
          stageName: 'Stage 4: Last Layer',
          algorithmName: 'PLL: ${matched.name}',
          moves: pllMoves,
          description: 'Permuting everything to finish the solve.',
        ));
        current = current.applyMoves(pllMoves);
      } else {
        // Fallback for PLL skip: Check if a simple U turn solves it
        for (int k = 0; k < 4; k++) {
          final align = k == 0 ? <CubeMove>[] : [CubeMove(CubeFace.u, k)];
          if (current.applyMoves(align).isSolved) {
            if (align.isNotEmpty) {
              steps.add(LblStep(
                stageName: 'Stage 4: Last Layer',
                moves: align,
                description: 'Align the top layer to finish the solve.',
              ));
              current = current.applyMoves(align);
            }
            break;
          }
        }
      }
    }

    if (!current.isSolved) return null;
    return steps;
  }

  // --- HELPERS ---



  static List<List<CubeMove>> _generateAll24Rotations() {
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

}

class _KTask {
  final String name;
  final bool Function(KociembaCube) isSolved;
  _KTask(this.name, this.isSolved);
}

class _KNode {
  final KociembaCube cube;
  final List<CubeMove> path;
  _KNode(this.cube, this.path);
}

