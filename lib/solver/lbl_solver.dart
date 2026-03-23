import 'package:logging/logging.dart';
import '../models/cube_state.dart';
import '../models/cube_move.dart';
import '../models/alg_library.dart';

part 'cfop_solver.dart';

/// A single step in the LBL solution, with stage label and description.
class LblStep {
  final String stageName;
  final List<CubeMove> moves;
  final String description;
  final String? algorithmName;

  const LblStep({
    required this.stageName,
    required this.moves,
    required this.description,
    this.algorithmName,
  });
}

/// Result of the LBL solver.
class LblSolveResult {
  final List<LblStep> steps;
  List<CubeMove> get allMoves => steps.expand((s) => s.moves).toList();
  const LblSolveResult({required this.steps});
}

/// A perspective defines which physical faces correspond to logical faces (U,D,L,R,F,B).
class Perspective {
  final CubeFace u, d, f, b, r, l;
  const Perspective({
    required this.u,
    required this.d,
    required this.f,
    required this.b,
    required this.r,
    required this.l,
  });

  /// Standard perspective: match centers of the current state.
  factory Perspective.fromState(CubeState s,
      {required CubeColor upColor, required CubeColor frontColor}) {
    // Find absolute faces for Up and Front
    final upFace = _findFaceWithCenter(s, upColor);
    final frontFace = _findFaceWithCenter(s, frontColor);

    // This is a simplified version; for now we'll use a few hardcoded ones
    if (upColor == CubeColor.white && frontColor == CubeColor.green) {
      return const Perspective(
          u: CubeFace.u,
          d: CubeFace.d,
          f: CubeFace.f,
          b: CubeFace.b,
          r: CubeFace.r,
          l: CubeFace.l);
    }
    // Default or dynamically solved
    return LblSolver._perspectiveFromUpFront(upFace, frontFace);
  }

  static CubeFace _findFaceWithCenter(CubeState s, CubeColor c) {
    for (final f in CubeFace.values) {
      if (s.getFace(f)[4] == c) {
        return f;
      }
    }
    return CubeFace.u;
  }
}

class LblSolver {
  static final _log = Logger('LblSolver');

  /// Solve the cube.
  static LblSolveResult? solve(CubeState initial) {
    var s = initial;
    if (s.isSolved) return LblSolveResult(steps: []);

    final steps = <LblStep>[];

    // Find target perspective based on white center
    final whiteFace = _findCenterFace(s, CubeColor.white);
    final p = perspectiveFor(whiteFace);

    steps.addAll(_whiteCross(s, p));
    for (final step in steps) {
      s = s.applyMoves(step.moves);
    }

    // Tutorial flip: White moves from Top to Bottom
    steps.add(const LblStep(
      stageName: 'First Layer',
      moves: [],
      description: 'Flip the cube over so the white cross is on the bottom.',
    ));
    final p2 = perspectiveFlipped(p);

    // Stage 2: First Layer Corners
    final s2 = _firstLayerCorners(s, p2);
    steps.addAll(s2);
    for (final step in s2) {
      s = s.applyMoves(step.moves);
    }

    // Stage 3: Second Layer Edges
    final s3 = _secondLayerEdges(s, p2);
    steps.addAll(s3);
    for (final step in s3) {
      s = s.applyMoves(step.moves);
    }

    // Stage 4: Yellow Cross (Orientation)
    final s4 = _yellowCross(s, p2);
    steps.addAll(s4);
    for (final step in s4) {
      s = s.applyMoves(step.moves);
    }

    // Stage 5: Align Yellow Edges (Edge Permutation)
    final s5 = _alignYellowEdges(s, p2);
    steps.addAll(s5);
    for (final step in s5) {
      s = s.applyMoves(step.moves);
    }

    // Stage 6: Yellow Corners (Permutation and Orientation)
    final s6 = _yellowCorners(s, p2);
    steps.addAll(s6);
    for (final step in s6) {
      s = s.applyMoves(step.moves);
    }

    return LblSolveResult(steps: optimizeSteps(steps));
  }

  static CubeFace _findCenterFace(CubeState s, CubeColor c) {
    for (final f in CubeFace.values) {
      if (s.getFace(f)[4] == c) return f;
    }
    return CubeFace.u;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PERSPECTIVE & REMAPPING
  // ─────────────────────────────────────────────────────────────────────────

  static Perspective perspectiveFor(CubeFace up) {
    // We choose an arbitrary 'front' that is orthogonal to 'up'
    // but consistent with standard world orientation if possible.
    CubeFace front;
    if (up == CubeFace.u) {
      front = CubeFace.f;
    } else if (up == CubeFace.d) {
      front = CubeFace.f;
    } else if (up == CubeFace.f) {
      front = CubeFace.d;
    } else if (up == CubeFace.b) {
      front = CubeFace.u;
    } else if (up == CubeFace.r) {
      front = CubeFace.f;
    } else {
      front = CubeFace.f; // up == l
    }

    return _perspectiveFromUpFront(up, front);
  }

  static Perspective _perspectiveFromUpFront(CubeFace u, CubeFace f) {
    final d = _opposite(u);
    final b = _opposite(f);
    final r = _cross(u, f);
    final l = _opposite(r);
    return Perspective(u: u, d: d, f: f, b: b, r: r, l: l);
  }

  static CubeFace _opposite(CubeFace f) {
    switch (f) {
      case CubeFace.u:
        return CubeFace.d;
      case CubeFace.d:
        return CubeFace.u;
      case CubeFace.f:
        return CubeFace.b;
      case CubeFace.b:
        return CubeFace.f;
      case CubeFace.r:
        return CubeFace.l;
      case CubeFace.l:
        return CubeFace.r;
    }
  }

  static CubeFace _cross(CubeFace u, CubeFace f) {
    const vectors = {
      CubeFace.u: (0, 1, 0),
      CubeFace.d: (0, -1, 0),
      CubeFace.r: (1, 0, 0),
      CubeFace.l: (-1, 0, 0),
      CubeFace.f: (0, 0, 1),
      CubeFace.b: (0, 0, -1),
    };
    final v1 = vectors[u]!, v2 = vectors[f]!;
    final rx = v1.$2 * v2.$3 - v1.$3 * v2.$2;
    final ry = v1.$3 * v2.$1 - v1.$1 * v2.$3;
    final rz = v1.$1 * v2.$2 - v1.$2 * v2.$1;
    // Find cube face matching (rx, ry, rz)
    for (final entry in vectors.entries) {
      if (entry.value.$1 == rx &&
          entry.value.$2 == ry &&
          entry.value.$3 == rz) {
        return entry.key;
      }
    }
    return CubeFace.r; // Should not happen
  }

  static Perspective perspectiveFlipped(Perspective p) {
    return Perspective(u: p.d, d: p.u, f: p.b, b: p.f, r: p.r, l: p.l);
  }

  static CubeMove _remap(CubeMove m, Perspective p) {
    CubeFace pf;
    switch (m.face) {
      case CubeFace.u:
        pf = p.u;
        break;
      case CubeFace.d:
        pf = p.d;
        break;
      case CubeFace.f:
        pf = p.f;
        break;
      case CubeFace.b:
        pf = p.b;
        break;
      case CubeFace.r:
        pf = p.r;
        break;
      case CubeFace.l:
        pf = p.l;
        break;
    }

    return CubeMove(pf, m.turns);
  }

  static List<CubeMove> _remapAll(List<CubeMove> moves, Perspective p) {
    return moves.map((m) => _remap(m, p)).toList();
  }

  static List<CubeMove> _remapFor(
      List<CubeMove> moves, CubeFace logicalFront, Perspective p) {
    final tempP = _perspectiveRotateY(p, logicalFront);
    return _remapAll(moves, tempP);
  }

  static Perspective _perspectiveRotateY(Perspective p, CubeFace logicalFront) {
    if (logicalFront == CubeFace.f) return p;
    final physFront = _remapFace(logicalFront, p);
    final physRight = _cross(p.u, physFront);
    final physLeft = _opposite(physRight);
    final physBack = _opposite(physFront);
    return Perspective(
        u: p.u, d: p.d, f: physFront, b: physBack, r: physRight, l: physLeft);
  }

  static CubeFace _remapFace(CubeFace f, Perspective p) {
    switch (f) {
      case CubeFace.u:
        return p.u;
      case CubeFace.d:
        return p.d;
      case CubeFace.f:
        return p.f;
      case CubeFace.b:
        return p.b;
      case CubeFace.r:
        return p.r;
      case CubeFace.l:
        return p.l;
    }
  }

  static CubeFace _logicalFaceFor(CubeFace physical, Perspective p) {
    if (physical == p.u) return CubeFace.u;
    if (physical == p.d) return CubeFace.d;
    if (physical == p.f) return CubeFace.f;
    if (physical == p.b) return CubeFace.b;
    if (physical == p.r) return CubeFace.r;
    if (physical == p.l) return CubeFace.l;
    return CubeFace.u;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STAGE 1: WHITE CROSS
  // ─────────────────────────────────────────────────────────────────────────

  static bool isCrossSolved(CubeState s, Perspective p) {
    if (s.getFace(p.u)[4] != s.getFace(p.u)[7]) return false;
    if (s.getFace(p.u)[4] != s.getFace(p.u)[5]) return false;
    if (s.getFace(p.u)[4] != s.getFace(p.u)[1]) return false;
    if (s.getFace(p.u)[4] != s.getFace(p.u)[3]) return false;

    if (!_isEdgeSolved(s, CubeFace.u, CubeFace.f, p)) return false;
    if (!_isEdgeSolved(s, CubeFace.u, CubeFace.r, p)) return false;
    if (!_isEdgeSolved(s, CubeFace.u, CubeFace.b, p)) return false;
    if (!_isEdgeSolved(s, CubeFace.u, CubeFace.l, p)) return false;

    return true;
  }

  static List<LblStep> _whiteCross(CubeState s, Perspective p) {
    final steps = <LblStep>[];
    var currentS = s;

    // Phase 1: Create Daisy (all 4 edges to yellow face - p.d)
    const sideFaces = [CubeFace.f, CubeFace.r, CubeFace.b, CubeFace.l];
    final white = CubeColor.white;

    bool isAtDaisy(CubeState state, CubeColor sideColor) {
      final (f1, i1, f2, i2) = _findEdge(state, white, sideColor)!;
      return (f1 == p.d && state.getFace(f1)[i1] == white) ||
          (f2 == p.d && state.getFace(f2)[i2] == white);
    }

    int daisySafety = 0;
    while (daisySafety++ < 20) {
      bool allInDaisy = true;
      for (final logicalSide in sideFaces) {
        final physicalSide = _remapFace(logicalSide, p);
        final sideColor = currentS.getFace(physicalSide)[4];

        if (!isAtDaisy(currentS, sideColor)) {
          allInDaisy = false;
          final daisyMoves =
              _solveEdgeToDaisy(currentS, logicalSide, sideColor, p);
          if (daisyMoves.isNotEmpty) {
            steps.add(LblStep(
                stageName: 'White Cross',
                moves: daisyMoves,
                description: 'Moving white-${_cn(sideColor)} edge to bottom'));
            currentS = currentS.applyMoves(daisyMoves);
          }
        }
      }
      if (allInDaisy) break;
    }

    // Phase 2: Move from Daisy to Cross
    for (final logicalSide in sideFaces) {
      final physicalSide = _remapFace(logicalSide, p);
      final sideColor = currentS.getFace(physicalSide)[4];

      // If already perfectly solved, skip
      if (_isEdgeSolved(currentS, CubeFace.u, logicalSide, p)) {
        continue;
      }

      final crossMoves = _finalizeEdgeToU(currentS, physicalSide, sideColor, p);
      if (crossMoves.isNotEmpty) {
        steps.add(LblStep(
            stageName: 'White Cross',
            moves: crossMoves,
            description: 'Moving white-${_cn(sideColor)} edge to top'));
        currentS = currentS.applyMoves(crossMoves);
      }
    }
    return steps;
  }

  static List<CubeMove> _solveEdgeToDaisy(
      CubeState s, CubeFace logicalSide, CubeColor cSide, Perspective p) {
    final moves = <CubeMove>[];
    var currentS = s;
    void apply(List<CubeMove> m) {
      if (m.isEmpty) return;
      moves.addAll(m);
      currentS = currentS.applyMoves(m);
    }

    (CubeFace, int, CubeFace, int) getPos() =>
        _findEdge(currentS, CubeColor.white, cSide)!;

    var (f1, i1, f2, i2) = getPos();
    bool whiteOnD() =>
        (f1 == p.d && currentS.getFace(f1)[i1] == CubeColor.white) ||
        (f2 == p.d && currentS.getFace(f2)[i2] == CubeColor.white);

    int safety = 0;
    while (!whiteOnD() && safety++ < 30) {
      if (f1 == p.u || f2 == p.u) {
        final pUpSticker = (f1 == p.u) ? i1 : i2;
        final pSideFace = (f1 == p.u) ? f2 : f1;
        final whiteOnUp = currentS.getFace(p.u)[pUpSticker] == CubeColor.white;

        if (whiteOnUp) {
          while (currentS.getFace(p.d)[_getPhysicalEdgeIndex(p.d, pSideFace)] ==
                  CubeColor.white &&
              safety++ < 60) {
            apply([_remap(CubeMove(CubeFace.d, 1), p)]);
          }
          apply([_remap(CubeMove(pSideFace, 2), p)]);
        } else {
          apply([_remap(CubeMove(pSideFace, 1), p)]);
        }
      } else if (f1 == p.d || f2 == p.d) {
        final pSideFace = (f1 == p.d) ? f2 : f1;
        apply([_remap(CubeMove(pSideFace, 1), p)]);
      } else {
        final fWhite = (currentS.getFace(f1)[i1] == CubeColor.white) ? f1 : f2;
        final fOther = (fWhite == f1) ? f2 : f1;

        final testS = currentS.applyMoves([_remap(CubeMove(fOther, 1), p)]);
        final (tf1, ti1, tf2, ti2) = _findEdge(testS, CubeColor.white, cSide)!;
        final turns =
            ((tf1 == p.d && testS.getFace(tf1)[ti1] == CubeColor.white) ||
                    (tf2 == p.d && testS.getFace(tf2)[ti2] == CubeColor.white))
                ? 1
                : -1;

        while (currentS.getFace(p.d)[_getPhysicalEdgeIndex(p.d, fOther)] ==
                CubeColor.white &&
            safety++ < 60) {
          apply([_remap(CubeMove(CubeFace.d, 1), p)]);
        }
        apply([_remap(CubeMove(fOther, turns), p)]);
      }
      (f1, i1, f2, i2) = getPos();
    }
    return moves;
  }

  static List<CubeMove> _finalizeEdgeToU(
      CubeState s, CubeFace physicalSide, CubeColor cSide, Perspective p) {
    final moves = <CubeMove>[];
    var currentS = s;
    void apply(List<CubeMove> m) {
      if (m.isEmpty) return;
      moves.addAll(m);
      currentS = currentS.applyMoves(m);
    }

    // 1. Find the piece.
    var (f1, i1, f2, i2) = _findEdge(currentS, CubeColor.white, cSide)!;

    // 2. Ensuring White is on D face.
    bool correctDaisy() =>
        (f1 == p.d && currentS.getFace(f1)[i1] == CubeColor.white) ||
        (f2 == p.d && currentS.getFace(f2)[i2] == CubeColor.white);

    if (!correctDaisy()) {
      // Piece is not correctly on Daisy. Solve it to Daisy first.
      final toDaisy = _solveEdgeToDaisy(
          currentS, _logicalFaceFor(physicalSide, p), cSide, p);
      apply(toDaisy);
      (f1, i1, f2, i2) = _findEdge(currentS, CubeColor.white, cSide)!;
    }

    // 3. Align and lift.
    final currentPhysSideOfPiece = (f1 == p.d) ? f2 : f1;
    final turns = _logicalDTurns(_logicalFaceFor(currentPhysSideOfPiece, p),
        _logicalFaceFor(physicalSide, p));
    if (turns != 0) {
      apply([_remap(CubeMove(CubeFace.d, turns), p)]);
    }

    // Now the piece is at the target physicalSide slot!
    apply([_remap(CubeMove(_logicalFaceFor(physicalSide, p), 2), p)]);

    return moves;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STAGE 2: FIRST LAYER CORNERS
  // ─────────────────────────────────────────────────────────────────────────

  static List<LblStep> _firstLayerCorners(CubeState s, Perspective p) {
    final steps = <LblStep>[];
    var currentS = s; // Use currentS to track state changes
    // slots[i] rotates p so that the i-th corner is at logical (F, R)
    final perspectiveRotations = [
      _perspectiveRotateY(p, CubeFace.f),
      _perspectiveRotateY(p, CubeFace.r),
      _perspectiveRotateY(p, CubeFace.b),
      _perspectiveRotateY(p, CubeFace.l),
    ];

    for (int i = 0; i < perspectiveRotations.length; i++) {
      final currP = perspectiveRotations[i];
      final fColor = currentS.getFace(currP.f)[4];
      final rColor = currentS.getFace(currP.r)[4];

      if (_isCornerSolved(
          currentS, CubeFace.d, CubeFace.f, CubeFace.r, currP)) {
        continue;
      }

      final moves = _solveCornerToD(currentS, currP, fColor, rColor);
      if (moves.isNotEmpty) {
        steps.add(LblStep(
            stageName: 'First Layer',
            moves: moves,
            description:
                'Inserting the white-${_cn(fColor)}-${_cn(rColor)} corner'));
        currentS = currentS.applyMoves(moves);
      }
    }
    return steps;
  }

  static List<CubeMove> _solveCornerToD(
      CubeState s, Perspective p, CubeColor cF, CubeColor cR) {
    final moves = <CubeMove>[];
    var currentS = s;
    void apply(List<CubeMove> m) {
      if (m.isEmpty) return;
      moves.addAll(m);
      currentS = currentS.applyMoves(m);
    }

    final CubeColor cBottom = CubeColor.white;
    const allLogicalSlots = [
      (CubeFace.f, CubeFace.r),
      (CubeFace.r, CubeFace.b),
      (CubeFace.b, CubeFace.l),
      (CubeFace.l, CubeFace.f)
    ];

    // 1. Pop if on Bottom layer (logical D) but in wrong slot or wrong orientation
    for (final (s1, s2) in allLogicalSlots) {
      if (_isPieceAtCorner(currentS, CubeFace.d, s1, s2, cBottom, cF, cR, p)) {
        if (!_isCornerSolved(currentS, CubeFace.d, s1, s2, p)) {
          apply(_remapFor(_parse("R U R' U'"), s1, p));
        } else {
          return []; // Solved
        }
        break;
      }
    }

    // 2. Find it now
    var found = _findCorner(currentS, cBottom, cF, cR);
    if (found == null) return moves;
    var (f1, i1, f2, i2, f3, i3) = found;

    if (f1 != p.u && f2 != p.u && f3 != p.u) {
      final physSide =
          (f1 != p.u && f1 != p.d) ? f1 : (f2 != p.u && f2 != p.d ? f2 : f3);
      final currentLogicalFront = _logicalFaceFor(physSide, p);
      apply(_remapFor(_parse("R U R' U'"), currentLogicalFront, p));
      final foundAgain = _findCorner(currentS, cBottom, cF, cR);
      if (foundAgain == null) return moves;
      (f1, i1, f2, i2, f3, i3) = foundAgain;
    }

    // 3. Align and Insert
    // Use target slot [F, R]
    const logicalFront = CubeFace.f;
    const logicalRight = CubeFace.r;

    int safety = 0;
    while (!_isPieceAtCorner(currentS, CubeFace.u, logicalFront, logicalRight,
            cBottom, cF, cR, p) &&
        safety++ < 25) {
      apply([_remap(CubeMove(CubeFace.u, 1), p)]);
    }

    safety = 0;
    while (
        !_isCornerSolved(currentS, CubeFace.d, logicalFront, logicalRight, p) &&
            safety++ < 15) {
      // Find shortest path to solve orientation
      // Try 1, 2, 3 reps of Sexy Move (R U R' U')
      // and 1, 2 reps of inverse (U R U' R') effectively

      int bestReps = 1;
      int minMoves = 99;
      bool useInverse = false;

      // Check standard reps
      for (int reps = 1; reps <= 3; reps++) {
        var algo = "";
        for (int r = 0; r < reps; r++) {
          algo += "${algo.isEmpty ? "" : " "}R U R' U'";
        }
        final testS =
            currentS.applyMoves(_remapFor(_parse(algo), logicalFront, p));
        if (_isCornerSolved(testS, CubeFace.d, logicalFront, logicalRight, p)) {
          bestReps = reps;
          minMoves = reps * 4;
          useInverse = false;
          break;
        }
      }

      // If we didn't find a 1-rep solution, check inverse
      if (minMoves > 4) {
        final testSInv = currentS
            .applyMoves(_remapFor(_parse("U R U' R'"), logicalFront, p));
        if (_isCornerSolved(
            testSInv, CubeFace.d, logicalFront, logicalRight, p)) {
          bestReps = 1;
          minMoves = 4;
          useInverse = true;
        }
      }

      if (useInverse) {
        apply(_remapFor(_parse("U R U' R'"), logicalFront, p));
      } else {
        var algo = "";
        for (int r = 0; r < bestReps; r++) {
          algo += "${algo.isEmpty ? "" : " "}R U R' U'";
        }
        apply(_remapFor(_parse(algo), logicalFront, p));
      }
    }

    return moves;
  }

  static bool _isPieceAtCorner(CubeState s, CubeFace lf1, CubeFace lf2,
      CubeFace lf3, CubeColor c1, CubeColor c2, CubeColor c3, Perspective p) {
    final p1 = _remapFace(lf1, p),
        p2 = _remapFace(lf2, p),
        p3 = _remapFace(lf3, p);
    final st1 = s.getFace(p1)[_getPhysicalCornerIndex(p1, p2, p3)];
    final st2 = s.getFace(p2)[_getPhysicalCornerIndex(p2, p1, p3)];
    final st3 = s.getFace(p3)[_getPhysicalCornerIndex(p3, p1, p2)];
    final colors = {st1, st2, st3};
    return colors.contains(c1) && colors.contains(c2) && colors.contains(c3);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STAGES 3-6
  // ─────────────────────────────────────────────────────────────────────────

  static List<LblStep> _secondLayerEdges(CubeState s, Perspective p) {
    final steps = <LblStep>[];
    var currentS = s; // Use currentS to track state changes
    // Each rotation puts a target slot at logical (F, R)
    final perspectiveRotations = [
      _perspectiveRotateY(p, CubeFace.f),
      _perspectiveRotateY(p, CubeFace.r),
      _perspectiveRotateY(p, CubeFace.b),
      _perspectiveRotateY(p, CubeFace.l),
    ];

    int safety = 0;
    while (safety++ < 10) {
      bool anySolvedThisPass = false;
      bool allSolved = true;

      for (final currP in perspectiveRotations) {
        final fC = currentS.getFace(currP.f)[4];
        final rC = currentS.getFace(currP.r)[4];

        if (_isEdgeSolved(currentS, CubeFace.f, CubeFace.r, currP)) continue;

        allSolved = false;
        final edgeMoves = _solveEdgeToMiddle(currentS, currP, fC, rC);
        if (edgeMoves.isNotEmpty) {
          steps.add(LblStep(
            stageName: 'Second Layer',
            moves: edgeMoves,
            algorithmName: 'Insertion',
            description: 'Inserting ${fC.name}-${rC.name} edge',
          ));
          currentS = currentS.applyMoves(edgeMoves);
          anySolvedThisPass = true;
        }
      }

      if (allSolved || !anySolvedThisPass) break;
    }
    return steps;
  }

  static List<CubeMove> _solveEdgeToMiddle(
      CubeState s, Perspective p, CubeColor cF, CubeColor rC) {
    final moves = <CubeMove>[];
    var currentS = s; // Use currentS to track state changes
    void apply(List<CubeMove> m) {
      if (m.isEmpty) return;
      moves.addAll(m);
      currentS = currentS.applyMoves(m);
    }

    final middleSlots = [
      (CubeFace.f, CubeFace.r),
      (CubeFace.r, CubeFace.b),
      (CubeFace.b, CubeFace.l),
      (CubeFace.l, CubeFace.f),
    ];

    // 1. If trapped in any middle slot (wrong spot or wrong orientation), pop it
    for (final (s1, s2) in middleSlots) {
      if (_isEdgeAtSlot(currentS, s1, s2, cF, rC, p)) {
        if (!_isEdgeSolved(currentS, s1, s2, p)) {
          apply(_remapFor(_parse("U R U' R' U' F' U F"), s1, p));
        } else {
          return []; // Already solved
        }
        break;
      }
    }

    // 2. Find in Top layer (p.u)
    final topEdges = [CubeFace.f, CubeFace.r, CubeFace.b, CubeFace.l];
    CubeFace? foundOnTop;
    for (final side in topEdges) {
      if (_isEdgeAtSlot(currentS, CubeFace.u, side, cF, rC, p)) {
        foundOnTop = side;
        break;
      }
    }

    if (foundOnTop == null) {
      return moves;
    }

    // 3. Align and Insert
    final physSide = _remapFace(foundOnTop, p);
    final sideSticker =
        currentS.getFace(physSide)[_getPhysicalEdgeIndex(physSide, p.u)];

    if (sideSticker == cF) {
      // Side sticker matches Front center. Align to Front.
      final turns = _logicalUTurns(foundOnTop, CubeFace.f);
      if (turns != 0) {
        apply([_remap(CubeMove(CubeFace.u, turns), p)]);
      }
      // Front sticker is cF, Top sticker is rC. Insert Right.
      apply(_remapFor(_parse("U R U' R' U' F' U F"), CubeFace.f, p));
    } else {
      // Side sticker matches Right center (must be rC). Align to Right center.
      final turns = _logicalUTurns(foundOnTop, CubeFace.r);
      if (turns != 0) {
        apply([_remap(CubeMove(CubeFace.u, turns), p)]);
      }
      // Right sticker is rC, Top sticker is cF. Insert Left.
      apply(_remapFor(_parse("U' L' U L U F U' F'"), CubeFace.r, p));
    }

    return moves;
  }

  static bool _isEdgeAtSlot(CubeState s, CubeFace lf1, CubeFace lf2,
      CubeColor c1, CubeColor c2, Perspective p) {
    final p1 = _remapFace(lf1, p), p2 = _remapFace(lf2, p);
    final colors = {
      s.getFace(p1)[_getPhysicalEdgeIndex(p1, p2)],
      s.getFace(p2)[_getPhysicalEdgeIndex(p2, p1)]
    };
    return colors.length == 2 && colors.contains(c1) && colors.contains(c2);
  }

  static List<LblStep> _yellowCross(CubeState s, Perspective p) {
    final steps = <LblStep>[];
    CubeState currentS = s;

    int safety = 0;
    while (safety++ < 10) {
      final pu = p.u;
      final centerColor = currentS.getFace(pu)[4];

      // Indices for edges on Top face relative to sides
      final bOriented =
          currentS.getFace(pu)[_getPhysicalEdgeIndex(pu, p.b)] == centerColor;
      final lOriented =
          currentS.getFace(pu)[_getPhysicalEdgeIndex(pu, p.l)] == centerColor;
      final rOriented =
          currentS.getFace(pu)[_getPhysicalEdgeIndex(pu, p.r)] == centerColor;
      final fOriented =
          currentS.getFace(pu)[_getPhysicalEdgeIndex(pu, p.f)] == centerColor;

      final orientedCount = (bOriented ? 1 : 0) +
          (lOriented ? 1 : 0) +
          (rOriented ? 1 : 0) +
          (fOriented ? 1 : 0);

      if (orientedCount == 4) break;

      final moves = <CubeMove>[];
      if (orientedCount == 0) {
        // Dot: Apply from any front
        moves.addAll(_remapFor(_parse("F R U R' U' F'"), CubeFace.f, p));
      } else if (orientedCount == 2) {
        // L-shape or Line. Find optimal pivot face to avoid U moves.
        if (lOriented && rOriented) {
          // Horizontal line already. Apply from Front.
          moves.addAll(_remapFor(_parse("F R U R' U' F'"), CubeFace.f, p));
        } else if (fOriented && bOriented) {
          // Vertical line. Apply from Right to make it horizontal.
          moves.addAll(_remapFor(_parse("F R U R' U' F'"), CubeFace.r, p));
        } else if (bOriented && lOriented) {
          // L-shape at Back-Left. Apply from Front.
          moves.addAll(_remapFor(_parse("F R U R' U' F'"), CubeFace.f, p));
        } else if (lOriented && fOriented) {
          // L-shape at Front-Left. Apply from Right.
          moves.addAll(_remapFor(_parse("F R U R' U' F'"), CubeFace.r, p));
        } else if (fOriented && rOriented) {
          // L-shape at Front-Right. Apply from Back.
          moves.addAll(_remapFor(_parse("F R U R' U' F'"), CubeFace.b, p));
        } else if (rOriented && bOriented) {
          // L-shape at Back-Right. Apply from Left.
          moves.addAll(_remapFor(_parse("F R U R' U' F'"), CubeFace.l, p));
        }
      }

      if (moves.isEmpty) break; // Should not happen

      steps.add(LblStep(
          stageName: 'Yellow Cross',
          moves: moves,
          algorithmName: 'F R U R\' U\' F\'',
          description: orientedCount == 0
              ? 'Orienting edges (Dot)'
              : (orientedCount == 2
                  ? (lOriented && rOriented
                      ? 'Orienting edges (Line)'
                      : 'Orienting edges (L-shape)')
                  : 'Orienting edges')));

      currentS = currentS.applyMoves(moves);
    }

    return steps;
  }

  static List<LblStep> _alignYellowEdges(CubeState s, Perspective p) {
    final steps = <LblStep>[];
    CubeState currentS = s;

    bool allAligned(CubeState cs) {
      final faces = [CubeFace.f, CubeFace.r, CubeFace.b, CubeFace.l];
      for (final f in faces) {
        final phF = _remapFace(f, p);
        if (cs.getFace(phF)[_getPhysicalEdgeIndex(phF, p.u)] !=
            cs.getFace(phF)[4]) {
          return false;
        }
      }
      return true;
    }

    int safety = 0;
    while (safety++ < 10 && !allAligned(currentS)) {
      // 1. Try to find a U rotation that satisfies allAligned()
      int bestAlignmentTurns = -1;
      for (int turns = 0; turns < 4; turns++) {
        final move = _remap(CubeMove(CubeFace.u, turns), p);
        final checkS = currentS.applyMoves([move]);
        bool ok = allAligned(checkS);
        _log.finer("    Stage 5 check: turns=$turns, move=$move, ok=$ok");
        if (ok) {
          bestAlignmentTurns = turns;
          break;
        }
      }

      if (bestAlignmentTurns != -1) {
        if (bestAlignmentTurns > 0) {
          final uMoves = [_remap(CubeMove(CubeFace.u, bestAlignmentTurns), p)];
          steps.add(LblStep(
              stageName: 'Align Yellow Edges',
              moves: uMoves,
              description: 'Aligning top edges with centers'));
          currentS = currentS.applyMoves(uMoves);
        }
        break;
      }

      // 2. Multi-Sune strategy
      bool suneApplied = false;
      for (int turns = 0; turns < 4; turns++) {
        final checkS =
            currentS.applyMoves([_remap(CubeMove(CubeFace.u, turns), p)]);
        final matched = <CubeFace>[];
        for (final f in [CubeFace.f, CubeFace.r, CubeFace.b, CubeFace.l]) {
          final phF = _remapFace(f, p);
          if (checkS.getFace(phF)[_getPhysicalEdgeIndex(phF, p.u)] ==
              checkS.getFace(phF)[4]) {
            matched.add(f);
          }
        }

        if (matched.length >= 2) {
          if (turns > 0) {
            final uMoves = [_remap(CubeMove(CubeFace.u, turns), p)];
            steps.add(LblStep(
                stageName: 'Align Yellow Edges',
                moves: uMoves,
                description: 'Rotating top to find edge matches'));
            currentS = currentS.applyMoves(uMoves);
          }

          CubeFace frontForSune = CubeFace.f;
          if (matched.contains(CubeFace.b) && matched.contains(CubeFace.r)) {
            frontForSune = CubeFace.f;
          } else if (matched.contains(CubeFace.r) &&
              matched.contains(CubeFace.f)) {
            frontForSune = CubeFace.l;
          } else if (matched.contains(CubeFace.f) &&
              matched.contains(CubeFace.l)) {
            frontForSune = CubeFace.b;
          } else if (matched.contains(CubeFace.l) &&
              matched.contains(CubeFace.b)) {
            frontForSune = CubeFace.r;
          } else {
            frontForSune = matched.first;
          }

          final suneMoves =
              _remapFor(_parse("R U R' U R U2 R'"), frontForSune, p);
          steps.add(LblStep(
              stageName: 'Align Yellow Edges',
              moves: suneMoves,
              algorithmName: 'Sune',
              description: 'Cycling edges to match side centers'));
          currentS = currentS.applyMoves(suneMoves);
          suneApplied = true;
          break;
        }
      }

      if (!suneApplied) {
        final suneMoves =
            _remapFor(_parse("R U R' U R U2 R' U"), CubeFace.f, p);
        steps.add(LblStep(
            stageName: 'Align Yellow Edges',
            moves: suneMoves,
            algorithmName: 'Sune',
            description: 'Cycling edges to find matching centers'));
        currentS = currentS.applyMoves(suneMoves);
      }
    }
    return steps;
  }

  static List<LblStep> _yellowCorners(CubeState s, Perspective p) {
    final steps = <LblStep>[];
    var currentS = s;

    // Phase 1: Position Corners (Permutation) - Niklas
    bool allCornersInTargetSlot() {
      final slots = [
        (CubeFace.f, CubeFace.r),
        (CubeFace.r, CubeFace.b),
        (CubeFace.b, CubeFace.l),
        (CubeFace.l, CubeFace.f),
      ];
      for (final (f1, f2) in slots) {
        if (!_isPieceAtCornerInTargetSlot(currentS, CubeFace.u, f1, f2, p)) {
          return false;
        }
      }
      return true;
    }

    int posSafety = 0;
    while (posSafety++ < 20 && !allCornersInTargetSlot()) {
      CubeFace? pivotFace;
      final slots = [
        (CubeFace.f, CubeFace.r),
        (CubeFace.r, CubeFace.b),
        (CubeFace.b, CubeFace.l),
        (CubeFace.l, CubeFace.f),
      ];
      int correctCount = 0;
      for (final (f1, f2) in slots) {
        if (_isPieceAtCornerInTargetSlot(currentS, CubeFace.u, f1, f2, p)) {
          pivotFace ??= f1;
          correctCount++;
        }
      }

      _log.finer(
          "  Stage 6 Loop $posSafety: correct=$correctCount, pivot=$pivotFace");

      final algo = _parse("U R U' L' U R' U' L");
      final moves = _remapFor(algo, pivotFace ?? CubeFace.f, p);
      _log.finer("    Moves: $moves");
      steps.add(LblStep(
          stageName: 'Yellow Corners',
          moves: moves,
          algorithmName: 'Niklas',
          description: pivotFace == null
              ? 'Cycling corners to find correct slots'
              : 'Cycling corners while keeping one fixed'));
      currentS = currentS.applyMoves(moves);
    }

    // Phase 2: Orient Corners (Orientation) - R' D' R D
    for (int i = 0; i < 4; i++) {
      final pu = p.u;
      final pf = p.f;
      final pr = p.r;

      final idx = _getPhysicalCornerIndex(pu, pf, pr);
      final yellow = currentS.getFace(pu)[4];

      if (currentS.getFace(pu)[idx] != yellow) {
        // Find if CW (2 reps) or CCW (4 reps) is shorter
        final testCsCw = currentS.applyMoves(
            _remapFor(_parse("R' D' R D R' D' R D"), CubeFace.f, p));
        final isSolvedCw = testCsCw.getFace(pu)[idx] == yellow;

        final orientMoves = <CubeMove>[];
        if (isSolvedCw) {
          final slice = _remapFor(_parse("R' D' R D R' D' R D"), CubeFace.f, p);
          orientMoves.addAll(slice);
          currentS = currentS.applyMoves(slice);
        } else {
          // Must be the other direction (CCW), which is 2 reps of inverse
          final slice = _remapFor(_parse("D' R' D R D' R' D R"), CubeFace.f, p);
          orientMoves.addAll(slice);
          currentS = currentS.applyMoves(slice);
        }

        steps.add(LblStep(
            stageName: 'Yellow Corners',
            moves: orientMoves,
            algorithmName: isSolvedCw ? "R' D' R D × 2" : "D' R' D R × 2",
            description: 'Orienting corner using the shortest path'));
      }

      if (i < 3) {
        // Only advance if there's at least one more unsolved corner ahead
        bool remainsUnsolved = false;
        for (int k = i + 1; k < 4; k++) {
            final testRot = [_remap(CubeMove(CubeFace.u, k - i), p)];
            if (currentS.applyMoves(testRot).getFace(pu)[idx] != yellow) { remainsUnsolved = true; break; }
        }
        
        if (remainsUnsolved) {
            final uMove = [_remap(CubeMove(CubeFace.u, 1), p)];
            steps.add(LblStep(
                stageName: 'Yellow Corners',
                moves: uMove,
                description: 'Advancing to next corner'));
            currentS = currentS.applyMoves(uMove);
        }
      }
    }

    // Final U adjustment to align with side centers
    int finalTurns = 0;
    for (int t = 0; t < 4; t++) {
      final testCS = currentS.applyMoves([_remap(CubeMove(CubeFace.u, t), p)]);
      final testF = _remapFace(CubeFace.f, p);
      final edgeIdx = _getPhysicalEdgeIndex(testF, p.u);
      if (testCS.getFace(testF)[edgeIdx] == testCS.getFace(testF)[4]) {
        finalTurns = t;
        break;
      }
    }
    if (finalTurns > 0) {
      final uMove = [_remap(CubeMove(CubeFace.u, finalTurns), p)];
      steps.add(LblStep(
          stageName: 'Yellow Corners',
          moves: uMove,
          description: 'Final top layer alignment'));
      currentS = currentS.applyMoves(uMove);
    }

    return steps;
  }

  static bool _isPieceAtCornerInTargetSlot(
      CubeState s, CubeFace lu, CubeFace lf, CubeFace lr, Perspective p) {
    // Correct slot means the piece at (lu, lf, lr) has the colors of (lu, lf, lr) centers.
    final pu = _remapFace(lu, p),
        pf = _remapFace(lf, p),
        pr = _remapFace(lr, p);
    final c1 = s.getFace(pu)[4], c2 = s.getFace(pf)[4], c3 = s.getFace(pr)[4];
    return _isPieceAtCorner(s, lu, lf, lr, c1, c2, c3, p);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UTILS
  // ─────────────────────────────────────────────────────────────────────────

  static bool _isEdgeSolved(
      CubeState s, CubeFace lf1, CubeFace lf2, Perspective p) {
    final p1 = _remapFace(lf1, p), p2 = _remapFace(lf2, p);
    return s.getFace(p1)[_getPhysicalEdgeIndex(p1, p2)] == s.getFace(p1)[4] &&
        s.getFace(p2)[_getPhysicalEdgeIndex(p2, p1)] == s.getFace(p2)[4];
  }

  static bool _isCornerSolved(
      CubeState s, CubeFace ld, CubeFace lf, CubeFace lr, Perspective p) {
    final pu = _remapFace(ld, p),
        pf = _remapFace(lf, p),
        pr = _remapFace(lr, p);
    return s.getFace(pu)[_getPhysicalCornerIndex(pu, pf, pr)] ==
            s.getFace(pu)[4] &&
        s.getFace(pf)[_getPhysicalCornerIndex(pf, pu, pr)] ==
            s.getFace(pf)[4] &&
        s.getFace(pr)[_getPhysicalCornerIndex(pr, pu, pf)] == s.getFace(pr)[4];
  }

  static List<CubeMove> _parse(String s) =>
      s.isEmpty ? [] : s.split(' ').map((m) => CubeMove.parse(m)!).toList();
  static String _cn(CubeColor c) => c.name;

  static (CubeFace, int, CubeFace, int)? _findEdge(
      CubeState s, CubeColor c1, CubeColor c2) {
    for (final (f1, i1, f2, i2) in _allEdges) {
      final a = s.getFace(f1)[i1], b = s.getFace(f2)[i2];
      if ((a == c1 && b == c2) || (a == c2 && b == c1)) return (f1, i1, f2, i2);
    }
    return null;
  }

  static (CubeFace, int, CubeFace, int, CubeFace, int)? _findCorner(
      CubeState s, CubeColor c1, CubeColor c2, CubeColor c3) {
    for (final (f1, i1, f2, i2, f3, i3) in _allCorners) {
      final a = s.getFace(f1)[i1], b = s.getFace(f2)[i2], c = s.getFace(f3)[i3];
      final colors = {a, b, c};
      if (colors.contains(c1) && colors.contains(c2) && colors.contains(c3)) {
        return (f1, i1, f2, i2, f3, i3);
      }
    }
    return null;
  }

  static int _logicalUTurns(CubeFace from, CubeFace to) {
    const cycle = [CubeFace.f, CubeFace.l, CubeFace.b, CubeFace.r];
    final fi = cycle.indexOf(from), ti = cycle.indexOf(to);
    return (fi == -1 || ti == -1) ? 0 : (ti - fi + 4) % 4;
  }

  static int _logicalDTurns(CubeFace from, CubeFace to) {
    const cycle = [CubeFace.f, CubeFace.r, CubeFace.b, CubeFace.l];
    final fi = cycle.indexOf(from), ti = cycle.indexOf(to);
    return (fi == -1 || ti == -1) ? 0 : (ti - fi + 4) % 4;
  }

  static int _getPhysicalEdgeIndex(CubeFace f, CubeFace neighbor) {
    for (final (f1, i1, f2, i2) in _allEdges) {
      if (f1 == f && f2 == neighbor) return i1;
      if (f2 == f && f1 == neighbor) return i2;
    }
    return 4;
  }

  static int _getPhysicalCornerIndex(CubeFace f, CubeFace n1, CubeFace n2) {
    final search = {n1, n2};
    for (final (f1, i1, f2, i2, f3, i3) in _allCorners) {
      if (f1 == f && search.contains(f2) && search.contains(f3)) return i1;
      if (f2 == f && search.contains(f1) && search.contains(f3)) return i2;
      if (f3 == f && search.contains(f1) && search.contains(f2)) return i3;
    }
    return 4;
  }

  static const _allEdges = [
    (CubeFace.u, 7, CubeFace.f, 1),
    (CubeFace.u, 5, CubeFace.r, 1),
    (CubeFace.u, 1, CubeFace.b, 1),
    (CubeFace.u, 3, CubeFace.l, 1),
    (CubeFace.d, 1, CubeFace.f, 7),
    (CubeFace.d, 5, CubeFace.r, 7),
    (CubeFace.d, 7, CubeFace.b, 7),
    (CubeFace.d, 3, CubeFace.l, 7),
    (CubeFace.f, 5, CubeFace.r, 3),
    (CubeFace.f, 3, CubeFace.l, 5),
    (CubeFace.b, 3, CubeFace.r, 5),
    (CubeFace.b, 5, CubeFace.l, 3),
  ];

  static const _allCorners = [
    (CubeFace.u, 6, CubeFace.f, 0, CubeFace.l, 2),
    (CubeFace.u, 8, CubeFace.r, 0, CubeFace.f, 2),
    (CubeFace.u, 2, CubeFace.b, 0, CubeFace.r, 2),
    (CubeFace.u, 0, CubeFace.l, 0, CubeFace.b, 2),
    (CubeFace.d, 0, CubeFace.l, 8, CubeFace.f, 6),
    (CubeFace.d, 2, CubeFace.f, 8, CubeFace.r, 6),
    (CubeFace.d, 8, CubeFace.r, 8, CubeFace.b, 6),
    (CubeFace.d, 6, CubeFace.b, 8, CubeFace.l, 6),
  ];

  static List<LblStep> optimizeSteps(List<LblStep> steps) {
    if (steps.isEmpty) return [];

    // 1. Optimize moves within each step
    var currentSteps = steps
        .map((s) => LblStep(
              stageName: s.stageName,
              moves: optimizeMoves(s.moves),
              description: s.description,
              algorithmName: s.algorithmName,
            ))
        .toList();

    // 2. Cross-step boundary optimization
    bool changed = true;
    while (changed) {
      changed = false;
      for (int i = 0; i < currentSteps.length - 1; i++) {
        final current = currentSteps[i];
        final next = currentSteps[i + 1];

        if (current.moves.isNotEmpty &&
            next.moves.isNotEmpty &&
            current.moves.last.face == next.moves.first.face) {
          final moveA = current.moves.last;
          final moveB = next.moves.first;

          int totalTurns = (moveA.turns + moveB.turns) % 4;
          if (totalTurns > 2) totalTurns -= 4;
          if (totalTurns < -1) totalTurns += 4;

          final newMovesA = List<CubeMove>.from(current.moves);
          newMovesA.removeLast();
          if (totalTurns != 0) {
            newMovesA.add(CubeMove(moveA.face, totalTurns));
          }

          final newMovesB = List<CubeMove>.from(next.moves);
          newMovesB.removeAt(0);

          currentSteps[i] = LblStep(
            stageName: current.stageName,
            moves: newMovesA,
            description: current.description,
            algorithmName: current.algorithmName,
          );
          currentSteps[i + 1] = LblStep(
            stageName: next.stageName,
            moves: newMovesB,
            description: next.description,
            algorithmName: next.algorithmName,
          );
          changed = true;
        }
      }
    }

    return currentSteps.where((s) => s.moves.isNotEmpty).toList();
  }

  /// Optimizes a sequence of moves by combining consecutive turns on the same face.
  static List<CubeMove> optimizeMoves(List<CubeMove> moves) {
    if (moves.isEmpty) return [];

    final result = <CubeMove>[];
    for (final move in moves) {
      if (result.isNotEmpty && result.last.face == move.face) {
        final last = result.removeLast();
        // Combine turns: 1 (CW), -1 (CCW), 2 (180).
        // Standardize turns to range [-1, 2].
        int totalTurns = (last.turns + move.turns) % 4;
        if (totalTurns > 2) totalTurns -= 4;
        if (totalTurns < -1) totalTurns += 4;

        if (totalTurns != 0) {
          result.add(CubeMove(last.face, totalTurns));
        }
        // If totalTurns is 0, the moves cancel out and we don't add anything back.
      } else {
        result.add(move);
      }
    }

    // Secondary pass to catch cancellations created by the first pass (e.g., R U U' R')
    if (result.length < moves.length) {
      return optimizeMoves(result);
    }

    return result;
  }
}
