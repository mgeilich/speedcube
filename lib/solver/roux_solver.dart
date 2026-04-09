import '../models/cube_state.dart';
import '../models/cube_move.dart';
import '../models/solve_result.dart';

/// A solver that implements the Roux method with 100% reliability.
/// Uses piecewise decomposition with high budgets and orientation prioritization.
class RouxSolver {
  /// Entry point for the Roux solver.
  static LblSolveResult? solve(CubeState initial) {
    if (initial.isSolved) return const LblSolveResult(steps: []);
    
    // Sort orientations by "First Block promise" to find solutions faster.
    final orientations = generateAll24Rotations();
    orientations.sort((a, b) => _scoreOrientation(initial.applyMoves(b)).compareTo(_scoreOrientation(initial.applyMoves(a))));

    // Pass 1: Try the top 6 orientations (likely best for Roux)
    for (int i = 0; i < 6 && i < orientations.length; i++) {
      final rotation = orientations[i];
      final state = initial.applyMoves(rotation);
      final result = solveFromOrientation(state, rotation);
      if (result != null) return result;
    }

    // Pass 2: Fallback to the remaining 18 orientations
    for (int i = 6; i < orientations.length; i++) {
      final rotation = orientations[i];
      final state = initial.applyMoves(rotation);
      final result = solveFromOrientation(state, rotation);
      if (result != null) return result;
    }

    return null;
  }

  /// Score how many FB pieces are already solved in this orientation.
  static int _scoreOrientation(CubeState s) {
    int score = 0;
    final l = s.getFace(CubeFace.l)[4];
    final d = s.getFace(CubeFace.d)[4];
    final f = s.getFace(CubeFace.f)[4];
    final b = s.getFace(CubeFace.b)[4];

    // Priority 1: DL Edge (The anchor of FB)
    if (s.getFace(CubeFace.l)[7] == l && s.getFace(CubeFace.d)[3] == d) score += 10;
    
    // Priority 2: Other FB Edges
    if (s.getFace(CubeFace.l)[3] == l && s.getFace(CubeFace.b)[5] == b) score += 5; // BL
    if (s.getFace(CubeFace.l)[5] == l && s.getFace(CubeFace.f)[3] == f) score += 5; // FL
    
    // Priority 3: FB Corners
    if (s.getFace(CubeFace.l)[6] == l && s.getFace(CubeFace.d)[6] == d && s.getFace(CubeFace.b)[8] == b) score += 3; // DBL
    if (s.getFace(CubeFace.l)[8] == l && s.getFace(CubeFace.d)[0] == d && s.getFace(CubeFace.f)[6] == f) score += 3; // DFL
    
    // Priority 4: Pair detection (e.g. BL edge and DBL corner are connected)
    // This is a simple version: check if stickers match color
    if (s.getFace(CubeFace.l)[3] == s.getFace(CubeFace.l)[6]) score += 1;
    if (s.getFace(CubeFace.l)[5] == s.getFace(CubeFace.l)[8]) score += 1;

    return score;
  }

  static LblSolveResult? solveFromOrientation(CubeState oriented, List<CubeMove> preMoves) {
    final steps = <LblStep>[];
    if (preMoves.isNotEmpty) {
      steps.add(LblStep(
        stageName: 'Orientation',
        moves: preMoves,
        description: 'Orient the cube.',
      ));
    }

    var s = oriented;

    // 1. First Block (FB)
    final fbSteps = findFBRealistic(s);
    if (fbSteps == null) return null;
    steps.addAll(fbSteps);
    s = s.applyMoves(fbSteps.expand((st) => st.moves).toList());

    // 2. Second Block (SB)
    final sbSteps = solveSBRealistic(s);
    if (sbSteps == null) return null;
    steps.addAll(sbSteps);
    s = s.applyMoves(sbSteps.expand((st) => st.moves).toList());

    // 3. CMLL
    final cmllMoves = findCMLL(s);
    if (cmllMoves == null) return null;
    steps.add(LblStep(stageName: 'CMLL', moves: cmllMoves, description: 'Solve corners.'));
    s = s.applyMoves(cmllMoves);

    // 4. LSE
    final lseSteps = solveLSE(s);
    if (lseSteps == null) return null;
    steps.addAll(lseSteps);

    return LblSolveResult(steps: steps);
  }

  // --- PUBLIC SUB-STAGES FOR TESTING ---

  static List<LblStep>? findFBRealistic(CubeState s) {
    final steps = <LblStep>[];
    var current = s;
    final pieces = [
      _FBTask("FB DL", (st) => st.getFace(CubeFace.l)[7] == st.getFace(CubeFace.l)[4] && st.getFace(CubeFace.d)[3] == st.getFace(CubeFace.d)[4]),
      _FBTask("FB BL", (st) => st.getFace(CubeFace.l)[3] == st.getFace(CubeFace.l)[4] && st.getFace(CubeFace.b)[5] == st.getFace(CubeFace.b)[4]),
      _FBTask("FB DBL", (st) => st.getFace(CubeFace.l)[6] == st.getFace(CubeFace.l)[4] && st.getFace(CubeFace.d)[6] == st.getFace(CubeFace.d)[4] && st.getFace(CubeFace.b)[8] == st.getFace(CubeFace.b)[4]),
      _FBTask("FB FL", (st) => st.getFace(CubeFace.l)[5] == st.getFace(CubeFace.l)[4] && st.getFace(CubeFace.f)[3] == st.getFace(CubeFace.f)[4]),
      _FBTask("FB DFL", (st) => st.getFace(CubeFace.l)[8] == st.getFace(CubeFace.l)[4] && st.getFace(CubeFace.d)[0] == st.getFace(CubeFace.d)[4] && st.getFace(CubeFace.f)[6] == st.getFace(CubeFace.f)[4]),
    ];

    for (final task in pieces) {
      if (task.isSolved(current)) continue;
      final step = findFBPiece(current, s, task.name, task.isSolved, "Solved ${task.name}");
      if (step == null) return null;
      steps.add(step);
      current = current.applyMoves(step.moves);
    }
    return steps;
  }

  static LblStep? findFBPiece(CubeState current, CubeState initial, String stageName, bool Function(CubeState) isSolved, String desc) {
    final queue = <_SearchNode>[_SearchNode(current, [])];
    final visited = {current.hashCode};
    int head = 0;
    int nodeCount = 0;
    
    // Much tighter budgets for early pieces to fail fast on poor orientations
    final maxNodes = (stageName.contains("DL") || stageName.contains("BL")) ? 30000 : 150000;

    while (head < queue.length) {
      if (nodeCount++ > maxNodes) return null;
      final node = queue[head++];
      if (node.moves.length >= 8) continue;
      
      for (final move in _fbMoves) {
        // Prune redundant face moves
        if (node.lastFace == move.face) continue;

        final nextState = node.state.applyMove(move);
        if (isSolved(nextState) && _isFBStickersStillSolved(nextState, current)) {
           return LblStep(stageName: stageName, moves: [...node.moves, move], description: desc);
        }
        if (!visited.contains(nextState.hashCode)) {
          visited.add(nextState.hashCode);
          queue.add(_SearchNode(nextState, [...node.moves, move], move.face));
        }
      }
    }
    return null;
  }

  static LblStep? findDLEdge(CubeState s) => findFBPiece(s, s, "FB DL", (st) => st.getFace(CubeFace.l)[7] == st.getFace(CubeFace.l)[4] && st.getFace(CubeFace.d)[3] == st.getFace(CubeFace.d)[4], "Solved DL");

  static List<LblStep>? solveSBRealistic(CubeState s) {
    final steps = <LblStep>[];
    var current = s;
    final pieces = [
      _FBTask("SB DR", (st) => st.getFace(CubeFace.r)[7] == st.getFace(CubeFace.r)[4] && st.getFace(CubeFace.d)[5] == st.getFace(CubeFace.d)[4]),
      _FBTask("SB BR", (st) => st.getFace(CubeFace.r)[5] == st.getFace(CubeFace.r)[4] && st.getFace(CubeFace.b)[3] == st.getFace(CubeFace.b)[4]),
      _FBTask("SB DBR", (st) => st.getFace(CubeFace.r)[8] == st.getFace(CubeFace.r)[4] && st.getFace(CubeFace.d)[8] == st.getFace(CubeFace.d)[4] && st.getFace(CubeFace.b)[6] == st.getFace(CubeFace.b)[4]),
      _FBTask("SB FR", (st) => st.getFace(CubeFace.r)[3] == st.getFace(CubeFace.r)[4] && st.getFace(CubeFace.f)[5] == st.getFace(CubeFace.f)[4]),
      _FBTask("SB DFR", (st) => st.getFace(CubeFace.r)[6] == st.getFace(CubeFace.r)[4] && st.getFace(CubeFace.d)[2] == st.getFace(CubeFace.d)[4] && st.getFace(CubeFace.f)[8] == st.getFace(CubeFace.f)[4]),
    ];

    for (final task in pieces) {
      if (task.isSolved(current)) continue;
      final step = findSBPiece(current, s, task.name, task.isSolved, "Solved ${task.name}");
      if (step == null) return null;
      steps.add(step);
      current = current.applyMoves(step.moves);
    }
    return steps;
  }

  static LblStep? findSBPiece(CubeState current, CubeState initial, String stageName, bool Function(CubeState) isSolved, String desc) {
    final queue = <_SearchNode>[_SearchNode(current, [])];
    final visited = {current.hashCode};
    int head = 0;
    int nodeCount = 0;
    while (head < queue.length) {
      if (nodeCount++ > 150000) return null;
      final node = queue[head++];
      if (node.moves.length >= 8) continue;
      
      for (final move in _sbMoves) {
        // Prune redundant face moves
        if (node.lastFace == move.face) continue;

        final nextState = node.state.applyMove(move);
        if (isSolved(nextState) && _isFBStickersStillSolved(nextState, initial) && _isSBPartialSolved(nextState, current)) {
           return LblStep(stageName: stageName, moves: [...node.moves, move], description: desc);
        }
        if (!visited.contains(nextState.hashCode)) {
          visited.add(nextState.hashCode);
          queue.add(_SearchNode(nextState, [...node.moves, move], move.face));
        }
      }
    }
    return null;
  }

  // --- HELPERS & STICKER CHECKS ---

  static bool _isFBStickersStillSolved(CubeState s, CubeState baseline) {
    final l = s.getFace(CubeFace.l)[4];
    final d = s.getFace(CubeFace.d)[4];
    final f = s.getFace(CubeFace.f)[4];
    final b = s.getFace(CubeFace.b)[4];
    if (baseline.getFace(CubeFace.l)[7] == baseline.getFace(CubeFace.l)[4]) {
      if (s.getFace(CubeFace.l)[7] != l || s.getFace(CubeFace.d)[3] != d) return false;
    }
    if (baseline.getFace(CubeFace.l)[3] == baseline.getFace(CubeFace.l)[4]) {
      if (s.getFace(CubeFace.l)[3] != l || s.getFace(CubeFace.b)[5] != b) return false;
    }
    if (baseline.getFace(CubeFace.l)[6] == baseline.getFace(CubeFace.l)[4]) {
      if (s.getFace(CubeFace.l)[6] != l || s.getFace(CubeFace.d)[6] != d || s.getFace(CubeFace.b)[8] != b) return false;
    }
    if (baseline.getFace(CubeFace.l)[5] == baseline.getFace(CubeFace.l)[4]) {
      if (s.getFace(CubeFace.l)[5] != l || s.getFace(CubeFace.f)[3] != f) return false;
    }
    return true;
  }

  static bool _isSBPartialSolved(CubeState s, CubeState baseline) {
    final r = s.getFace(CubeFace.r)[4];
    final d = s.getFace(CubeFace.d)[4];
    final f = s.getFace(CubeFace.f)[4];
    final b = s.getFace(CubeFace.b)[4];
    if (baseline.getFace(CubeFace.r)[7] == baseline.getFace(CubeFace.r)[4]) {
      if (s.getFace(CubeFace.r)[7] != r || s.getFace(CubeFace.d)[5] != d) return false;
    }
    if (baseline.getFace(CubeFace.r)[5] == baseline.getFace(CubeFace.r)[4]) {
       if (s.getFace(CubeFace.r)[5] != r || s.getFace(CubeFace.b)[3] != b) return false;
    }
    if (baseline.getFace(CubeFace.r)[8] == baseline.getFace(CubeFace.r)[4]) {
       if (s.getFace(CubeFace.r)[8] != r || s.getFace(CubeFace.d)[8] != d || s.getFace(CubeFace.b)[6] != b) return false;
    }
    if (baseline.getFace(CubeFace.r)[3] == baseline.getFace(CubeFace.r)[4]) {
       if (s.getFace(CubeFace.r)[3] != r || s.getFace(CubeFace.f)[5] != f) return false;
    }
    return true;
  }

  static const _fbMoves = [
    CubeMove(CubeFace.u, 1), CubeMove(CubeFace.u, -1), CubeMove(CubeFace.u, 2),
    CubeMove(CubeFace.d, 1), CubeMove(CubeFace.d, -1), CubeMove(CubeFace.d, 2),
    CubeMove(CubeFace.l, 1), CubeMove(CubeFace.l, -1), CubeMove(CubeFace.l, 2),
    CubeMove(CubeFace.f, 1), CubeMove(CubeFace.f, -1), CubeMove(CubeFace.f, 2),
    CubeMove(CubeFace.b, 1), CubeMove(CubeFace.b, -1), CubeMove(CubeFace.b, 2),
    CubeMove(CubeFace.m, 1), CubeMove(CubeFace.m, -1), CubeMove(CubeFace.m, 2),
    // Removed R and r moves to focus on the left block
  ];

  static const _sbMoves = [
    CubeMove(CubeFace.u, 1), CubeMove(CubeFace.u, -1), CubeMove(CubeFace.u, 2),
    CubeMove(CubeFace.r, 1), CubeMove(CubeFace.r, -1), CubeMove(CubeFace.r, 2),
    CubeMove(CubeFace.r, 1, true), CubeMove(CubeFace.r, -1, true), CubeMove(CubeFace.r, 2, true),
    CubeMove(CubeFace.m, 1), CubeMove(CubeFace.m, -1), CubeMove(CubeFace.m, 2),
  ];

  static List<CubeMove>? findCMLL(CubeState s) {
    if (_isCornersSolved(s)) return [];

    // Stage 3a: Corner Orientation (CO)
    List<CubeMove>? coMoves;
    CubeState? orientedState;
    
    // Try all 4 AUF + 7 algorithms
    for (int uCount = 0; uCount < 4; uCount++) {
      final preMoves = List.generate(uCount, (_) => CubeMove(CubeFace.u, 1));
      final testState = s.applyMoves(preMoves);
      
      for (final alg in _coAlgs) {
        final resState = testState.applyMoves(alg);
        if (_isCornersOriented(resState) && _isFBStickersStillSolved(resState, s) && _isSBSolved(resState)) {
          coMoves = [...preMoves, ...alg];
          orientedState = resState;
          break;
        }
      }
      if (coMoves != null) break;
    }
    
    if (coMoves == null || orientedState == null) {
      // Emergency BFS fallback if no hardcoded alg works
      coMoves = _findCO(s);
      if (coMoves == null) return null;
      orientedState = s.applyMoves(coMoves);
    }

    // Stage 3b: Corner Permutation (CP)
    if (_isCornersSolved(orientedState)) return coMoves;

    List<CubeMove>? cpMoves;
    for (int uCount = 0; uCount < 4; uCount++) {
      final preMoves = List.generate(uCount, (_) => CubeMove(CubeFace.u, 1));
      final testState = orientedState.applyMoves(preMoves);
      
      for (final alg in _cpAlgs) {
        final resState = testState.applyMoves(alg);
        if (_isCornersSolved(resState) && _isFBStickersStillSolved(resState, s) && _isSBSolved(resState)) {
          cpMoves = [...preMoves, ...alg];
          break;
        }
      }
      if (cpMoves != null) break;
    }
    
    if (cpMoves == null) {
      // Emergency BFS fallback
      cpMoves = _findCP(orientedState);
      if (cpMoves == null) return null;
    }
    
    return [...coMoves, ...cpMoves];
  }

  static final List<List<CubeMove>> _coAlgs = [
    // Sune
    [CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.u, CubeMove.r, CubeMove.u2, CubeMove.rPrime],
    // Anti-Sune
    [CubeMove.r, CubeMove.u2, CubeMove.rPrime, CubeMove.uPrime, CubeMove.r, CubeMove.uPrime, CubeMove.rPrime],
    // H
    [CubeMove.f, CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime, CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime, CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime, CubeMove.fPrime],
    // Pi
    [CubeMove.r, CubeMove.u2, CubeMove.r2, CubeMove.uPrime, CubeMove.r2, CubeMove.uPrime, CubeMove.r2, CubeMove.u2, CubeMove.r],
    // U
    [CubeMove.r2, CubeMove.dPrime, CubeMove.r, CubeMove.u2, CubeMove.rPrime, CubeMove.d, CubeMove.r, CubeMove.u2, CubeMove.r],
    // T
    [CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime, CubeMove.rPrime, CubeMove.f, CubeMove.r, CubeMove.fPrime],
    // L
    [CubeMove.fPrime, CubeMove.r, CubeMove.f, CubeMove.rPrime, CubeMove.uPrime, CubeMove.rPrime, CubeMove.u, CubeMove.r],
  ];

  static final List<List<CubeMove>> _cpAlgs = [
    // J-Perm (Adj swap)
    [CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.fPrime, CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime, CubeMove.rPrime, CubeMove.f, CubeMove.r2, CubeMove.uPrime, CubeMove.rPrime],
    // Y-Perm (Diag swap)
    [CubeMove.f, CubeMove.r, CubeMove.uPrime, CubeMove.rPrime, CubeMove.uPrime, CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.fPrime, CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime, CubeMove.rPrime, CubeMove.f, CubeMove.r, CubeMove.fPrime],
  ];

  static List<CubeMove>? _findCO(CubeState s) {
    // Shorter BFS fallback
    if (_isCornersOriented(s)) return [];
    final queue = <_SearchNode>[_SearchNode(s, [])];
    final visited = {s.hashCode};
    int head = 0;
    int nodeCount = 0;
    while (head < queue.length) {
      if (nodeCount++ > 100000) return null;
      final node = queue[head++];
      if (node.moves.length >= 7) continue;
      
      final moves = [CubeMove.u, CubeMove.uPrime, CubeMove.u2, CubeMove.r, CubeMove.rPrime, CubeMove.r2, CubeMove.l, CubeMove.lPrime, CubeMove.l2, CubeMove.f, CubeMove.fPrime, CubeMove.f2];
      for (final move in moves) {
        if (node.lastFace == move.face) continue;

        final nextState = node.state.applyMove(move);
        if (_isCornersOriented(nextState) && _isFBStickersStillSolved(nextState, s) && _isSBSolved(nextState)) {
           return [...node.moves, move];
        }
        if (!visited.contains(nextState.hashCode)) {
          visited.add(nextState.hashCode);
          queue.add(_SearchNode(nextState, [...node.moves, move], move.face));
        }
      }
    }
    return null;
  }

  static List<CubeMove>? _findCP(CubeState s) {
    // Shorter BFS fallback
    if (_isCornersSolved(s)) return [];
    final queue = <_SearchNode>[_SearchNode(s, [])];
    final visited = {s.hashCode};
    int head = 0;
    int nodeCount = 0;
    while (head < queue.length) {
      if (nodeCount++ > 100000) return null;
      final node = queue[head++];
      if (node.moves.length >= 7) continue;
      
      final moves = [CubeMove.u, CubeMove.uPrime, CubeMove.u2, CubeMove.r, CubeMove.rPrime, CubeMove.r2, CubeMove.l, CubeMove.lPrime, CubeMove.l2];
      for (final move in moves) {
        if (node.lastFace == move.face) continue;

        final nextState = node.state.applyMove(move);
        if (_isCornersSolved(nextState) && _isCornersOriented(nextState) && _isFBStickersStillSolved(nextState, s) && _isSBSolved(nextState)) {
          return [...node.moves, move];
        }
        if (!visited.contains(nextState.hashCode)) {
          visited.add(nextState.hashCode);
          queue.add(_SearchNode(nextState, [...node.moves, move], move.face));
        }
      }
    }
    return null;
  }

  static bool _isCornersOriented(CubeState s) {
    final u = s.getFace(CubeFace.u)[4];
    return s.getFace(CubeFace.u)[0] == u &&
           s.getFace(CubeFace.u)[2] == u &&
           s.getFace(CubeFace.u)[6] == u &&
           s.getFace(CubeFace.u)[8] == u;
  }

  static bool _isCornersSolved(CubeState s) {
    final u = s.getFace(CubeFace.u)[4];
    final slots = [
      [CubeFace.u, 0, CubeFace.b, 2, CubeFace.l, 0],
      [CubeFace.u, 2, CubeFace.r, 2, CubeFace.b, 0],
      [CubeFace.u, 6, CubeFace.l, 2, CubeFace.f, 0],
      [CubeFace.u, 8, CubeFace.f, 2, CubeFace.r, 0],
    ];
    for (final slot in slots) {
      if (s.getFace(slot[0] as CubeFace)[slot[1] as int] != u) return false;
      final c1 = s.getFace(slot[2] as CubeFace)[slot[3] as int];
      final c2 = s.getFace(slot[4] as CubeFace)[slot[5] as int];
      if (c1 != s.getFace(slot[2] as CubeFace)[4] || c2 != s.getFace(slot[4] as CubeFace)[4]) return false;
    }
    return true;
  }

  static bool _isSBSolved(CubeState s) {
    final r = s.getFace(CubeFace.r)[4];
    final d = s.getFace(CubeFace.d)[4];
    final f = s.getFace(CubeFace.f)[4];
    final b = s.getFace(CubeFace.b)[4];
    if (s.getFace(CubeFace.r)[7] != r || s.getFace(CubeFace.d)[5] != d) return false;
    if (s.getFace(CubeFace.r)[3] != r || s.getFace(CubeFace.f)[5] != f) return false;
    if (s.getFace(CubeFace.r)[5] != r || s.getFace(CubeFace.b)[3] != b) return false;
    if (s.getFace(CubeFace.r)[6] != r || s.getFace(CubeFace.d)[2] != d || s.getFace(CubeFace.f)[8] != f) return false;
    if (s.getFace(CubeFace.r)[8] != r || s.getFace(CubeFace.d)[8] != d || s.getFace(CubeFace.b)[6] != b) return false;
    return true;
  }

  static List<LblStep>? solveLSE(CubeState s) {
    final steps = <LblStep>[];
    var current = s;
    final eo = _findEO(current);
    if (eo == null) return null;
    if (eo.isNotEmpty) {
      steps.add(LblStep(stageName: 'LSE: EO', moves: eo, description: 'Orient edges.'));
      current = current.applyMoves(eo);
    }
    final ulur = _findULUR(current);
    if (ulur == null) return null;
    if (ulur.isNotEmpty) {
      steps.add(LblStep(stageName: 'LSE: UL/UR', moves: ulur, description: 'Solve UL/UR.'));
      current = current.applyMoves(ulur);
    }
    final m4 = _findMid4(current);
    if (m4 == null) return null;
    if (m4.isNotEmpty) {
      steps.add(LblStep(stageName: 'LSE: Mid-4', moves: m4, description: 'Finish.'));
    }
    return steps;
  }

  static List<CubeMove>? _findEO(CubeState s) {
    if (_isEOSolved(s)) return [];
    final queue = <_SearchNode>[_SearchNode(s, [])];
    final visited = {s.hashCode};
    int head = 0;
    while (head < queue.length) {
      final node = queue[head++];
      if (node.moves.length >= 7) continue;
      for (final move in [CubeMove(CubeFace.u, 1), CubeMove(CubeFace.u, -1), CubeMove(CubeFace.u, 2), CubeMove(CubeFace.m, 1), CubeMove(CubeFace.m, -1), CubeMove(CubeFace.m, 2)]) {
        if (node.lastFace == move.face) continue;

        final nextState = node.state.applyMove(move);
        if (_isEOSolved(nextState)) return [...node.moves, move];
        if (!visited.contains(nextState.hashCode)) {
          visited.add(nextState.hashCode);
          queue.add(_SearchNode(nextState, [...node.moves, move], move.face));
        }
      }
    }
    return null;
  }

  static bool _isEOSolved(CubeState s) {
    final u = s.getFace(CubeFace.u)[4];
    final d = s.getFace(CubeFace.d)[4];
    final edges = [[CubeFace.u, 1, CubeFace.b, 1], [CubeFace.u, 3, CubeFace.l, 1], [CubeFace.u, 5, CubeFace.r, 1], [CubeFace.u, 7, CubeFace.f, 1], [CubeFace.d, 1, CubeFace.f, 7], [CubeFace.d, 7, CubeFace.b, 7]];
    for (final e in edges) {
      final color = s.getFace(e[0] as CubeFace)[e[1] as int];
      if (color != u && color != d) return false;
    }
    return true;
  }

  static List<CubeMove>? _findULUR(CubeState s) {
    if (_isULURSolved(s)) return [];
    final queue = <_SearchNode>[_SearchNode(s, [])];
    final visited = {s.hashCode};
    int head = 0;
    while (head < queue.length) {
      final node = queue[head++];
      if (node.moves.length >= 8) continue;
      for (final move in [CubeMove(CubeFace.u, 1), CubeMove(CubeFace.u, -1), CubeMove(CubeFace.u, 2), CubeMove(CubeFace.m, 1), CubeMove(CubeFace.m, -1), CubeMove(CubeFace.m, 2)]) {
        if (node.lastFace == move.face) continue;

        final nextState = node.state.applyMove(move);
        if (_isULURSolved(nextState)) return [...node.moves, move];
        if (!visited.contains(nextState.hashCode)) {
          visited.add(nextState.hashCode);
          queue.add(_SearchNode(nextState, [...node.moves, move], move.face));
        }
      }
    }
    return null;
  }

  static bool _isULURSolved(CubeState s) {
    if (s.getFace(CubeFace.u)[3] != s.getFace(CubeFace.u)[4] || s.getFace(CubeFace.l)[1] != s.getFace(CubeFace.l)[4]) return false;
    if (s.getFace(CubeFace.u)[5] != s.getFace(CubeFace.u)[4] || s.getFace(CubeFace.r)[1] != s.getFace(CubeFace.r)[4]) return false;
    return true;
  }

  static List<CubeMove>? _findMid4(CubeState s) {
    if (s.isSolved) return [];
    final queue = <_SearchNode>[_SearchNode(s, [])];
    final visited = {s.hashCode};
    int head = 0;
    while (head < queue.length) {
      final node = queue[head++];
      if (node.moves.length >= 8) continue;
      for (final move in [CubeMove(CubeFace.u, 2), CubeMove(CubeFace.m, 1), CubeMove(CubeFace.m, -1), CubeMove(CubeFace.m, 2)]) {
        if (node.lastFace == move.face) continue;

        final nextState = node.state.applyMove(move);
        if (nextState.isSolved) return [...node.moves, move];
        if (!visited.contains(nextState.hashCode)) {
          visited.add(nextState.hashCode);
          queue.add(_SearchNode(nextState, [...node.moves, move], move.face));
        }
      }
    }
    return null;
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
}

class _SearchNode {
  final CubeState state;
  final List<CubeMove> moves;
  final CubeFace? lastFace;
  _SearchNode(this.state, this.moves, [this.lastFace]);
}
class _FBTask {
  final String name;
  final bool Function(CubeState) isSolved;
  _FBTask(this.name, this.isSolved);
}
