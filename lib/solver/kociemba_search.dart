import 'package:logging/logging.dart';
import 'kociemba_tables.dart';
import 'kociemba_coordinates.dart';
import '../models/cube_state.dart';
import '../models/cube_move.dart';

class KociembaSearch {
  static final _log = Logger('KociembaSearch');

  final Stopwatch _stopwatch = Stopwatch();
  final int timeLimitMs;
  final int maxTotalDepth;

  List<CubeMove>? _bestSolution;
  int _bestSolutionLength = 999;

  KociembaSearch({this.timeLimitMs = 400, this.maxTotalDepth = 24});

  Future<KociembaSolveResult?> solve(CubeState state) async {
    await KociembaTables.init();
    final cube = KociembaCube.fromCubeState(state);

    if (cube.isSolved) {
      return KociembaSolveResult(moves: [], phase1MoveCount: 0);
    }

    _stopwatch.start();
    _bestSolution = null;
    _bestSolutionLength = 999;

    // We search for Phase 1 solutions of increasing depth
    // For each one, we try to solve Phase 2 such that total length is minimized.
    for (int p1Depth = 0; p1Depth <= 12; p1Depth++) {
      if (_stopwatch.elapsedMilliseconds > timeLimitMs) break;

      final p1Moves = <int>[];
      if (_searchP1(
          cube.twist, cube.flip, cube.slice, p1Depth, p1Moves, -1, cube)) {
        // If we found a "perfect" solution (<= 19 moves), we can stop early
        if (_bestSolutionLength <= 19) break;
      }

      // If we already have a decent solution and we've spent some time, don't go deeper in P1
      if (_bestSolution != null &&
          _stopwatch.elapsedMilliseconds > timeLimitMs / 2) {
        break;
      }
    }

    if (_bestSolution == null) return null;

    // We need to find the Phase 1 count for our best solution.
    // Our search is designed to return the first (shortest Phase 1) solution it finds.
    // For now, let's just use the current logic but store the p1 count.
    return KociembaSolveResult(
      moves: _bestSolution!,
      phase1MoveCount: _bestSolutionPhase1Count,
    );
  }

  int _bestSolutionPhase1Count = 0;

  bool _searchP1(int tw, int fl, int sl, int depth, List<int> moves,
      int lastFace, KociembaCube originalCube) {
    if (_stopwatch.elapsedMilliseconds > timeLimitMs) return false;

    int h1 = KociembaTables.twistSlicePrun[tw * KociembaTables.nSlice + sl];
    int h2 = KociembaTables.flipSlicePrun[fl * KociembaTables.nSlice + sl];
    int h = h1 > h2 ? h1 : h2;

    if (h == 0) {
      // Phase 1 solved! Now try Phase 2.
      if (_solveP2(moves, originalCube)) {
        _bestSolutionPhase1Count = moves.length;
        return true;
      }
      return false;
    }

    if (h > depth) return false;

    // If current depth + heuristic already exceeds our best solution, prune
    if (moves.length + h >= _bestSolutionLength) return false;

    for (int face = 0; face < 6; face++) {
      if (face == lastFace) continue;
      if (lastFace != -1 && _isOpposite(face, lastFace) && face < lastFace) {
        continue;
      }

      for (int turns = 0; turns < 3; turns++) {
        int m = face * 3 + turns;
        moves.add(m);
        if (_searchP1(
            KociembaTables.twistMove[tw][m],
            KociembaTables.flipMove[fl][m],
            KociembaTables.sliceMove[sl][m],
            depth - 1,
            moves,
            face,
            originalCube)) {
          // Keep searching even if we found one, to find shorter ones?
          // Actually Kociemba typically returns the first one that satisfies the current limit.
          // But we want to find the best within the time limit.
          if (_bestSolutionLength <= 19) return true;
        }
        moves.removeLast();
      }
    }
    return false;
  }

  bool _solveP2(List<int> p1Moves, KociembaCube originalCube) {
    // Clone and apply P1 moves to get to G1
    final cube = KociembaCube.clone(originalCube);
    for (final m in p1Moves) {
      cube.applyMove(KociembaCube.allFaces[m ~/ 3], (m % 3) + 1);
    }

    final cp = cube.cpRank;
    final ep = cube.epRank;
    final usp = cube.uspRank;

    // Search for P2 solution that makes total <= current best
    int maxP2Depth = _bestSolutionLength - p1Moves.length - 1;
    if (maxP2Depth < 0) maxP2Depth = 15; // Initial search

    for (int depth = 0; depth <= maxP2Depth; depth++) {
      if (_stopwatch.elapsedMilliseconds > timeLimitMs) break;

      final p2Moves = <int>[];
      if (_searchP2(cp, ep, usp, depth, p2Moves, -1)) {
        final totalMovesInt = [...p1Moves, ...p2Moves];
        final solution = _intMovesToCubeMoves(totalMovesInt);

        if (solution.length < _bestSolutionLength) {
          _bestSolution = solution;
          _bestSolutionLength = solution.length;
          _log.fine('Found solution of length $_bestSolutionLength');
        }
        return true;
      }
    }
    return false;
  }

  bool _searchP2(
      int cp, int ep, int usp, int depth, List<int> moves, int lastFace) {
    int h1 = KociembaTables.cpUspPrun[cp * KociembaTables.nSlicePerm + usp];
    int h2 = KociembaTables.epUspPrun[ep * KociembaTables.nSlicePerm + usp];
    int h = h1 > h2 ? h1 : h2;

    if (h == 0) return true;
    if (h > depth) return false;

    for (int mIdx = 0; mIdx < 10; mIdx++) {
      int moveIdx = KociembaTables.phase2AvailableMoves[mIdx];
      int face = moveIdx ~/ 3;
      if (face == lastFace) continue;
      if (lastFace != -1 && _isOpposite(face, lastFace) && face < lastFace) {
        continue;
      }

      moves.add(moveIdx);
      if (_searchP2(
          KociembaTables.cpMove[cp][mIdx],
          KociembaTables.epMove[ep][mIdx],
          KociembaTables.uspMove[usp][mIdx],
          depth - 1,
          moves,
          face)) {
        return true;
      }
      moves.removeLast();
    }
    return false;
  }

  bool _isOpposite(int f1, int f2) {
    if (f1 > f2) {
      int t = f1;
      f1 = f2;
      f2 = t;
    }
    return (f1 == 0 && f2 == 1) || (f1 == 2 && f2 == 3) || (f1 == 4 && f2 == 5);
  }

  List<CubeMove> _intMovesToCubeMoves(List<int> moves) {
    return moves.map((m) {
      final faceIdx = m ~/ 3;
      final turnsIdx = m % 3;
      return CubeMove(
          KociembaCube.allFaces[faceIdx], turnsIdx == 2 ? -1 : turnsIdx + 1);
    }).toList();
  }
}

class KociembaSolveResult {
  final List<CubeMove> moves;
  final int phase1MoveCount;

  KociembaSolveResult({required this.moves, required this.phase1MoveCount});
}

class KociembaSolver {
  static Future<void> init() async {
    await KociembaTables.init();
  }

  static Future<KociembaSolveResult> solve(CubeState state) async {
    final search = KociembaSearch(timeLimitMs: 400);
    final result = await search.solve(state);
    return result ?? KociembaSolveResult(moves: [], phase1MoveCount: 0);
  }
}
