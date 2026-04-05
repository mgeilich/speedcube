import '../models/cube_state.dart';
import '../models/cube_move.dart';
import '../models/alg_library.dart';
import '../models/solve_result.dart';

/// A perspective defines which physical faces correspond to logical faces (U,D,L,R,F,B).
/// Duplicated from LblSolver for independence.
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
  static const identity = Perspective(u: CubeFace.u, d: CubeFace.d, f: CubeFace.f, b: CubeFace.b, r: CubeFace.r, l: CubeFace.l);

  factory Perspective.fromState(CubeState s,
      {required CubeColor upColor, required CubeColor frontColor}) {
    final upFace = _findFaceWithCenter(s, upColor);
    final frontFace = _findFaceWithCenter(s, frontColor);

    if (upColor == CubeColor.white && frontColor == CubeColor.green) {
      return const Perspective(
          u: CubeFace.u,
          d: CubeFace.d,
          f: CubeFace.f,
          b: CubeFace.b,
          r: CubeFace.r,
          l: CubeFace.l);
    }
    return CfopSolver._perspectiveFromUpFront(upFace, frontFace);
  }

  static CubeFace _findFaceWithCenter(CubeState s, CubeColor c) {
    for (final f in CubeFace.physicalFaces) {
      if (s.getFace(f)[4] == c) {
        return f;
      }
    }
    return CubeFace.u;
  }
}

class CfopSolver {

  /// Solve the cube using CFOP (Cross + F2L + OLL + PLL)
  static LblSolveResult? solve(CubeState initial) {
    var s = initial;
    if (s.isSolved) {
      return const LblSolveResult(steps: []);
    }

    final steps = <LblStep>[];
    final orientationMoves = <CubeMove>[];
    
    // 1. Physically Move White to Bottom (CubeFace.d)
    final whiteFace = _findCenterFace(initial, CubeColor.white);
    if (whiteFace == CubeFace.u) { orientationMoves.add(CubeMove.x2); }
    else if (whiteFace == CubeFace.f) { orientationMoves.add(CubeMove.xPrime); }
    else if (whiteFace == CubeFace.b) { orientationMoves.add(CubeMove.x); }
    else if (whiteFace == CubeFace.l) { orientationMoves.add(CubeMove.zPrime); }
    else if (whiteFace == CubeFace.r) { orientationMoves.add(CubeMove.z); }
    
    s = initial.applyMoves(orientationMoves);
    
    // 2. Physically Move Green to Front (CubeFace.f)
    // After moving white to bottom, yellow is at top. Green must be on sides.
    CubeFace greenFace = _findCenterFace(s, CubeColor.green);
    if (greenFace == CubeFace.b) { orientationMoves.add(CubeMove.y2); }
    else if (greenFace == CubeFace.r) { orientationMoves.add(CubeMove.y); }
    else if (greenFace == CubeFace.l) { orientationMoves.add(CubeMove.yPrime); }
    
    s = initial.applyMoves(orientationMoves);
    final p = Perspective.identity;

    // 0. Orientation Note
    steps.add(LblStep(
      stageName: 'Orientation',
      moves: orientationMoves,
      description: 'Orient the cube with white on bottom and ${_cn(s.getFace(p.f)[4])} on front.',
    ));

    // 1. Cross
    if (!isCrossSolved(s, p)) {
      final crossSteps = _whiteCross(s, p);
      for (final step in crossSteps) {
        s = s.applyMoves(step.moves);
        steps.add(step);
      }
    }

    // 2. F2L
    final s2 = _f2l(s, p);
    for (final step in s2) {
      s = s.applyMoves(step.moves);
      steps.add(step);
    }

    // 3. OLL
    final s3 = _oll(s, p);
    for (final step in s3) {
      s = s.applyMoves(step.moves);
      steps.add(step);
    }

    // 4. PLL
    final s4 = _pll(s, p);
    for (final step in s4) {
      s = s.applyMoves(step.moves);
      steps.add(step);
    }
    
    // Final check for tiny gaps or errors in beginner fallbacks
    if (!s.isSolved) {
      final align = _alignYellowEdges(s, p);
      for (final st in align) {
        s = s.applyMoves(st.moves);
        steps.add(st);
      }
    }
    if (!s.isSolved) {
      final corners = _yellowCorners(s, p);
      for (final st in corners) {
        s = s.applyMoves(st.moves);
        steps.add(st);
      }
    }

    return LblSolveResult(steps: optimizeSteps(steps));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CFOP STAGES
  // ─────────────────────────────────────────────────────────────────────────

  static List<LblStep> _f2l(CubeState s, Perspective p) {
    final steps = <LblStep>[];
    var currentS = s;
    final slots = [CubeFace.f, CubeFace.r, CubeFace.b, CubeFace.l];
    
    for (final slotF in slots) {
      final currP = _perspectiveRotateY(p, slotF);
      final cF = currentS.getFace(currP.f)[4];
      final cR = currentS.getFace(currP.r)[4];
      
      bool isSlotSolved(CubeState cs) =>
          _isCornerSolved(cs, CubeFace.d, CubeFace.f, CubeFace.r, currP) &&
          _isEdgeSolved(cs, CubeFace.f, CubeFace.r, currP);

      if (isSlotSolved(currentS)) {
        continue;
      }

      // Try 1-look F2L algorithms
      AlgCase? matched; int uTurns = 0;
      final f2lCases = AlgLibrary.f2l;
      
      outer: for (int i = 0; i < 4; i++) {
        final setupMoves = i == 0 ? <CubeMove>[] : [_remap(CubeMove(CubeFace.u, i), currP)];
        final trialS = currentS.applyMoves(setupMoves);
        for (final c in f2lCases) {
          final algoMoves = _remapAll(c.algorithmMoves, currP);
          if (isSlotSolved(trialS.applyMoves(algoMoves))) {
            matched = c; uTurns = i; break outer;
          }
        }
      }

      if (matched != null) {
        final setup = uTurns == 0 ? <CubeMove>[] : [_remap(CubeMove(CubeFace.u, uTurns), currP)];
        steps.add(LblStep(
          stageName: 'CFOP F2L', 
          algorithmName: matched.name, 
          moves: [...setup, ..._remapAll(matched.algorithmMoves, currP)], 
          description: 'Solving ${_cn(cF)}-${_cn(cR)} pair'
        ));
        currentS = currentS.applyMoves(steps.last.moves);
      } else {
        // Fallback to robust two-step solving
        if (!_isCornerSolved(currentS, CubeFace.d, CubeFace.f, CubeFace.r, currP)) {
          final cornerMoves = _solveCornerToD(currentS, currP, cF, cR);
          if (cornerMoves.isNotEmpty) {
            steps.add(LblStep(
                stageName: 'CFOP F2L',
                moves: cornerMoves,
                description: 'Solving ${_cn(cF)}-${_cn(cR)} corner'));
            currentS = currentS.applyMoves(cornerMoves);
          }
        }

        if (!_isEdgeSolved(currentS, CubeFace.f, CubeFace.r, currP)) {
          final edgeMoves = _solveEdgeToMiddle(currentS, currP, cF, cR);
          if (edgeMoves.isNotEmpty) {
            steps.add(LblStep(
                stageName: 'CFOP F2L',
                moves: edgeMoves,
                description: 'Solving ${_cn(cF)}-${_cn(cR)} edge'));
            currentS = currentS.applyMoves(edgeMoves);
          }
        }
      }
    }
    return steps;
  }

  static List<LblStep> _oll(CubeState s, Perspective p) {
    var currentS = s;
    final steps = <LblStep>[];
    final y = currentS.getFace(p.u)[4];

    bool isOllOriented(CubeState cs) => cs.getFace(p.u).every((stk) => stk == y);
    
    if (!isOllOriented(currentS)) {
      AlgCase? matched; int uTurns = 0;
      final ollCases = AlgLibrary.oll;
      
      outer: for (int i=0; i<4; i++) {
        final setupMoves = i == 0 ? <CubeMove>[] : [_remap(CubeMove(CubeFace.u, i), p)];
        final trialS = currentS.applyMoves(setupMoves);
        for (final c in ollCases) {
          if (isOllOriented(trialS.applyMoves(_remapAll(c.algorithmMoves, p)))) {
            matched = c; uTurns = i; break outer;
          }
        }
      }

      if (matched != null) {
        final setup = uTurns == 0 ? <CubeMove>[] : [_remap(CubeMove(CubeFace.u, uTurns), p)];
        steps.add(LblStep(
          stageName: 'CFOP OLL', 
          algorithmName: matched.name, 
          moves: [...setup, ..._remapAll(matched.algorithmMoves, p)], 
          description: 'Orienting the top layer'
        ));
      } else {
        // 2-look OLL Fallback
        if (!isCrossOriented(currentS, y, p)) {
          final crossSteps = _yellowCross(currentS, p);
          steps.addAll(crossSteps);
          for (final step in crossSteps) {
            currentS = currentS.applyMoves(step.moves);
          }
        }
        AlgCase? matched2; int uTurns2 = 0;
        final crossOllCases = AlgLibrary.oll.where((c) => c.subcategory == 'Cross' || c.id.startsWith('oll2')).toList();
        outer2: for (int i=0; i<4; i++) {
          final setup = i == 0 ? <CubeMove>[] : [_remap(CubeMove(CubeFace.u, i), p)];
          final trialS = currentS.applyMoves(setup);
          for (final c in crossOllCases) {
            if (isOllOriented(trialS.applyMoves(_remapAll(c.algorithmMoves, p)))) {
              matched2 = c; uTurns2 = i; break outer2;
            }
          }
        }
        if (matched2 != null) {
          final setup = uTurns2 == 0 ? <CubeMove>[] : [_remap(CubeMove(CubeFace.u, uTurns2), p)];
          steps.add(LblStep(
            stageName: 'CFOP OLL', 
            algorithmName: matched2.name, 
            moves: [...setup, ..._remapAll(matched2.algorithmMoves, p)], 
            description: 'Orienting top corners'
          ));
        } else {
          // Final desperate fallback to LBL corners
          steps.addAll(_yellowCorners(currentS, p));
        }
      }
    }
    return steps;
  }

  static bool isCrossOriented(CubeState cs, CubeColor y, Perspective p) {
    final u = cs.getFace(p.u);
    return u[1] == y && u[3] == y && u[5] == y && u[7] == y;
  }

  static List<LblStep> _pll(CubeState s, Perspective p) {
    final steps = <LblStep>[];
    var currentS = s;

    List<CubeColor> getStickersAdjacentToU(CubeState cs, CubeFace f) {
        final c1Idx = _getPhysicalCornerIndex(f, p.u, _perspectiveRotateY(p, f).l);
        final eIdx = _getPhysicalEdgeIndex(f, p.u);
        final c2Idx = _getPhysicalCornerIndex(f, p.u, _perspectiveRotateY(p, f).r);
        final face = cs.getFace(f);
        return [face[c1Idx], face[eIdx], face[c2Idx]];
    }

    bool isSideSolved(CubeState cs) {
      for (final f in [p.f, p.r, p.b, p.l]) {
        final row = getStickersAdjacentToU(cs, f);
        final center = cs.getFace(f)[4];
        if (row[0] != center || row[1] != center || row[2] != center) {
          return false;
        }
      }
      return true;
    }

    bool cornersCorrect(CubeState cs) {
      for (final f in [p.f, p.r, p.b, p.l]) {
        final row = getStickersAdjacentToU(cs, f);
        if (row[0] != row[2]) {
          return false;
        }
      }
      return true;
    }

    // Try 1-look PLL first (all 21 cases)
    AlgCase? matched; int uTurns = 0; int finalAlign = 0;
    
    outer: for (int i=0; i<4; i++) {
      final setup = i == 0 ? <CubeMove>[] : [_remap(CubeMove(CubeFace.u, i), p)];
      final trialS = currentS.applyMoves(setup);
      for (final c in AlgLibrary.pll) {
        final algoMoves = _remapAll(c.algorithmMoves, p);
        final nextS = trialS.applyMoves(algoMoves);
        for (int k=0; k<4; k++) {
          final lastMove = k == 0 ? <CubeMove>[] : [_remap(CubeMove(CubeFace.u, k), p)];
          if (isSideSolved(nextS.applyMoves(lastMove))) {
            matched = c; uTurns = i; finalAlign = k; break outer;
          }
        }
      }
    }

    if (matched != null && matched.id != 'pll_solved') {
      final setup = uTurns == 0 ? <CubeMove>[] : [_remap(CubeMove(CubeFace.u, uTurns), p)];
      final finalize = finalAlign == 0 ? <CubeMove>[] : [_remap(CubeMove(CubeFace.u, finalAlign), p)];
      steps.add(LblStep(
        stageName: 'CFOP PLL', 
        algorithmName: matched.name, 
        moves: [...setup, ..._remapAll(matched.algorithmMoves, p), ...finalize], 
        description: 'Solving top layer'
      ));
      return steps;
    }

    // 2-look PLL Fallback
    if (!isSideSolved(currentS)) {
      if (!cornersCorrect(currentS)) {
        AlgCase? cMatched; int cuTurns = 0;
        final cornerCases = AlgLibrary.pll.where((c) => c.subcategory.contains('Corner Swap') || c.id == 'pll_t' || c.id == 'pll_y').toList();
        outer2: for (int i=0; i<4; i++) {
          final setup = i == 0 ? <CubeMove>[] : [_remap(CubeMove(CubeFace.u, i), p)];
          final trialS = currentS.applyMoves(setup);
          for (final c in cornerCases) {
            if (cornersCorrect(trialS.applyMoves(_remapAll(c.algorithmMoves, p)))) {
              cMatched = c; cuTurns = i; break outer2;
            }
          }
        }
        if (cMatched != null) {
          final setup = cuTurns == 0 ? <CubeMove>[] : [_remap(CubeMove(CubeFace.u, cuTurns), p)];
          steps.add(LblStep(
            stageName: 'CFOP PLL Corners', 
            algorithmName: cMatched.name, 
            moves: [...setup, ..._remapAll(cMatched.algorithmMoves, p)], 
            description: 'Permuting corners'
          ));
          currentS = currentS.applyMoves(steps.last.moves);
        }
      }

      int alignTurns = 0;
      for (int i=0; i<4; i++) {
        final move = _remap(CubeMove(CubeFace.u, i), p);
        final testS = currentS.applyMoves([move]);
        if (getStickersAdjacentToU(testS, p.f)[0] == testS.getFace(p.f)[4]) {
          alignTurns = i; break;
        }
      }
      if (alignTurns != 0) {
        final move = _remap(CubeMove(CubeFace.u, alignTurns), p);
        steps.add(LblStep(stageName: 'CFOP PLL Align', moves: [move], description: 'Aligning corners'));
        currentS = currentS.applyMoves([move]);
      }

      if (!isSideSolved(currentS)) {
        AlgCase? eMatched; int euTurns = 0;
        final edgeCases = AlgLibrary.pll.where((c) => c.subcategory == 'Edges Only').toList();
        outer3: for (int i=0; i<4; i++) {
          final setup = i == 0 ? <CubeMove>[] : [_remap(CubeMove(CubeFace.u, i), p)];
          final trialS = currentS.applyMoves(setup);
          for (final c in edgeCases) {
            if (isSideSolved(trialS.applyMoves(_remapAll(c.algorithmMoves, p)))) {
              eMatched = c; euTurns = i; break outer3;
            }
          }
        }
        if (eMatched != null) {
          final setup = euTurns == 0 ? <CubeMove>[] : [_remap(CubeMove(CubeFace.u, euTurns), p)];
          steps.add(LblStep(
            stageName: 'CFOP PLL Edges', 
            algorithmName: eMatched.name, 
            moves: [...setup, ..._remapAll(eMatched.algorithmMoves, p)], 
            description: 'Permuting edges'
          ));
          currentS = currentS.applyMoves(steps.last.moves);
        } else {
          steps.addAll(_alignYellowEdges(currentS, p));
          currentS = currentS.applyMoves(steps.last.moves);
        }
      }
    }

    int finalTurns = 0;
    for (int i=0; i<4; i++) {
      final move = _remap(CubeMove(CubeFace.u, i), p);
      if (currentS.applyMoves([move]).isSolved) {
        finalTurns = i; break;
      }
    }
    if (finalTurns != 0) {
      steps.add(LblStep(stageName: 'CFOP Final Adjust', moves: [_remap(CubeMove(CubeFace.u, finalTurns), p)], description: 'Final turn to solve'));
    }

    return steps;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DUPLICATED UTILS (from LblSolver)
  // ─────────────────────────────────────────────────────────────────────────

  static (CubeFace, int, CubeFace, int)? _findEdge(CubeState s, CubeColor c1, CubeColor c2) {
    for (final (f1, i1, f2, i2) in _allEdges) {
      final a = s.getFace(f1)[i1], b = s.getFace(f2)[i2];
      if ((a == c1 && b == c2) || (a == c2 && b == c1)) return (f1, i1, f2, i2);
    }
    return null;
  }

  static (CubeFace, int, CubeFace, int, CubeFace, int)? _findCorner(CubeState s, CubeColor c1, CubeColor c2, CubeColor c3) {
    for (final (f1, i1, f2, i2, f3, i3) in _allCorners) {
      final a = s.getFace(f1)[i1], b = s.getFace(f2)[i2], c = s.getFace(f3)[i3];
      final colors = {a, b, c};
      if (colors.contains(c1) && colors.contains(c2) && colors.contains(c3)) {
        return (f1, i1, f2, i2, f3, i3);
      }
    }
    return null;
  }

  static bool isCrossSolved(CubeState s, Perspective p) {
    final pd = s.getFace(p.d);
    if (pd[4] != pd[7] || pd[4] != pd[5] || pd[4] != pd[1] || pd[4] != pd[3]) return false;
    if (!_isEdgeSolved(s, CubeFace.d, CubeFace.f, p)) return false;
    if (!_isEdgeSolved(s, CubeFace.d, CubeFace.r, p)) return false;
    if (!_isEdgeSolved(s, CubeFace.d, CubeFace.b, p)) return false;
    if (!_isEdgeSolved(s, CubeFace.d, CubeFace.l, p)) return false;
    return true;
  }

  static List<LblStep> _whiteCross(CubeState s, Perspective p) {
    final steps = <LblStep>[];
    var currentS = s;
    const sideFaces = [CubeFace.f, CubeFace.r, CubeFace.b, CubeFace.l];
    final white = CubeColor.white;

    bool isAtDaisy(CubeState state, CubeColor sideColor) {
      final edge = _findEdge(state, white, sideColor);
      if (edge == null) {
        return false;
      }
      final (f1, i1, f2, i2) = edge;
      return (f1 == p.u && state.getFace(f1)[i1] == white) ||
          (f2 == p.u && state.getFace(f2)[i2] == white);
    }

    int daisySafety = 0;
    while (daisySafety++ < 20) {
      bool allInDaisy = true;
      for (final logicalSide in sideFaces) {
        final phSide = _remapFace(logicalSide, p);
        final sideColor = currentS.getFace(phSide)[4];
        if (!isAtDaisy(currentS, sideColor)) {
          allInDaisy = false;
          final moves = _solveEdgeToDaisy(currentS, logicalSide, sideColor, p);
          if (moves.isNotEmpty) {
            steps.add(LblStep(stageName: 'CFOP Cross', moves: moves, description: 'Moving white-${_cn(sideColor)} edge to top'));
            currentS = currentS.applyMoves(moves);
          }
        }
      }
      if (allInDaisy) {
        break;
      }
    }

    for (final logicalSide in sideFaces) {
      final phSide = _remapFace(logicalSide, p);
      final sideColor = currentS.getFace(phSide)[4];
      if (_isEdgeSolved(currentS, CubeFace.d, logicalSide, p)) {
        continue;
      }
      final moves = _finalizeEdgeToD(currentS, phSide, sideColor, p);
      if (moves.isNotEmpty) {
        steps.add(LblStep(stageName: 'CFOP Cross', moves: moves, description: 'Moving white-${_cn(sideColor)} edge to bottom'));
        currentS = currentS.applyMoves(moves);
      }
    }
    return steps;
  }

  static List<CubeMove> _solveEdgeToDaisy(CubeState s, CubeFace logicalSide, CubeColor cSide, Perspective p) {
    final moves = <CubeMove>[];
    var currentS = s;
    void apply(List<CubeMove> m) { moves.addAll(m); currentS = currentS.applyMoves(m); }
    bool whiteOnU() {
      final edge = _findEdge(currentS, CubeColor.white, cSide);
      if (edge == null) return false;
      final (f1, i1, f2, i2) = edge;
      return (f1 == p.u && currentS.getFace(f1)[i1] == CubeColor.white) ||
          (f2 == p.u && currentS.getFace(f2)[i2] == CubeColor.white);
    }
    int safety = 0;
    while (!whiteOnU() && safety++ < 20) {
      final edge = _findEdge(currentS, CubeColor.white, cSide)!;
      final (f1, i1, f2, i2) = edge;
      if (f1 == p.d || f2 == p.d) {
        final pSideFace = (f1 == p.d) ? f2 : f1;
        if (currentS.getFace(p.d)[(f1 == p.d) ? i1 : i2] == CubeColor.white) {
          while (currentS.getFace(p.u)[_getPhysicalEdgeIndex(p.u, pSideFace)] == CubeColor.white && safety++ < 60) {
            apply([_remap(CubeMove(CubeFace.u, 1), p)]);
          }
          apply([CubeMove(pSideFace, 2)]);
        } else {
          apply([CubeMove(pSideFace, 1)]);
        }
      } else if (f1 == p.u || f2 == p.u) {
        final pSideFace = (f1 == p.u) ? f2 : f1;
        apply([CubeMove(pSideFace, 1)]);
      } else {
        final fWhite = (currentS.getFace(f1)[i1] == CubeColor.white) ? f1 : f2;
        final fOther = (fWhite == f1) ? f2 : f1;
        while (currentS.getFace(p.u)[_getPhysicalEdgeIndex(p.u, fOther)] == CubeColor.white && safety++ < 60) {
          apply([_remap(CubeMove(CubeFace.u, 1), p)]);
        }
        apply([CubeMove(fOther, 1)]);
      }
    }
    return moves;
  }

  static List<CubeMove> _finalizeEdgeToD(CubeState s, CubeFace physicalSide, CubeColor cSide, Perspective p) {
    final moves = <CubeMove>[];
    var currentS = s;
    void apply(List<CubeMove> m) { moves.addAll(m); currentS = currentS.applyMoves(m); }
    var edge = _findEdge(currentS, CubeColor.white, cSide)!;
    if (!((edge.$1 == p.u && currentS.getFace(edge.$1)[edge.$2] == CubeColor.white) ||
        (edge.$3 == p.u && currentS.getFace(edge.$3)[edge.$4] == CubeColor.white))) {
      apply(_solveEdgeToDaisy(currentS, _logicalFaceFor(physicalSide, p), cSide, p));
      edge = _findEdge(currentS, CubeColor.white, cSide)!;
    }
    final physSideOfPiece = (edge.$1 == p.u) ? edge.$3 : edge.$1;
    final turns = _logicalUTurns(_logicalFaceFor(physSideOfPiece, p), _logicalFaceFor(physicalSide, p));
    if (turns != 0) {
      apply([_remap(CubeMove(CubeFace.u, turns), p)]);
    }
    apply([CubeMove(physicalSide, 2)]);
    return moves;
  }

  static List<CubeMove> _solveCornerToD(CubeState s, Perspective p, CubeColor cF, CubeColor cR) {
    final moves = <CubeMove>[];
    var currentS = s;
    void apply(List<CubeMove> m) { moves.addAll(m); currentS = currentS.applyMoves(m); }
    const white = CubeColor.white;
    const allSlots = [(CubeFace.f, CubeFace.r), (CubeFace.r, CubeFace.b), (CubeFace.b, CubeFace.l), (CubeFace.l, CubeFace.f)];

    for (final (s1, s2) in allSlots) {
      if (_isPieceAtCorner(currentS, CubeFace.d, s1, s2, white, cF, cR, p)) {
        if (!_isCornerSolved(currentS, CubeFace.d, s1, s2, p)) {
          apply(_remapFor(_parse("R U R' U'"), s1, p));
        } else {
          return [];
        }
        break;
      }
    }
    var fnd = _findCorner(currentS, white, cF, cR);
    if (fnd == null) {
      return moves;
    }
    if (fnd.$1 != p.u && fnd.$3 != p.u && fnd.$5 != p.u) {
      final ps = (fnd.$1 != p.u && fnd.$1 != p.d) ? fnd.$1 : (fnd.$3 != p.u && fnd.$3 != p.d ? fnd.$3 : fnd.$5);
      final currentLogicalFront = _logicalFaceFor(ps, p);
      apply(_remapFor(_parse("R U R' U'"), currentLogicalFront, p));
      fnd = _findCorner(currentS, white, cF, cR)!;
    }

    int safety = 0;
    while (!_isPieceAtCorner(currentS, CubeFace.u, CubeFace.f, CubeFace.r, white, cF, cR, p) && safety++ < 25) {
      apply([_remap(CubeMove(CubeFace.u, 1), p)]);
    }
    safety = 0;
    while (!_isCornerSolved(currentS, CubeFace.d, CubeFace.f, CubeFace.r, p) && safety++ < 15) {
        int bestReps = 1; int minMoves = 99; bool useInverse = false;
        for (int reps = 1; reps <= 3; reps++) {
          var algo = List.filled(reps, "R U R' U'").join(" ");
          final testS = currentS.applyMoves(_remapFor(_parse(algo), CubeFace.f, p));
          if (_isCornerSolved(testS, CubeFace.d, CubeFace.f, CubeFace.r, p)) {
            bestReps = reps; minMoves = reps * 4; useInverse = false; break;
          }
        }
        if (minMoves > 4) {
          final testSInv = currentS.applyMoves(_remapFor(_parse("U R U' R'"), CubeFace.f, p));
          if (_isCornerSolved(testSInv, CubeFace.d, CubeFace.f, CubeFace.r, p)) {
            bestReps = 1; minMoves = 4; useInverse = true;
          }
        }
        if (useInverse) {
          apply(_remapFor(_parse("U R U' R'"), CubeFace.f, p));
        } else {
          apply(_remapFor(_parse(List.filled(bestReps, "R U R' U'").join(" ")), CubeFace.f, p));
        }
    }
    return moves;
  }

  static List<CubeMove> _solveEdgeToMiddle(CubeState s, Perspective p, CubeColor cF, CubeColor cR) {
    final moves = <CubeMove>[];
    var currentS = s;
    void apply(List<CubeMove> m) { moves.addAll(m); currentS = currentS.applyMoves(m); }
    const slots = [(CubeFace.f, CubeFace.r), (CubeFace.r, CubeFace.b), (CubeFace.b, CubeFace.l), (CubeFace.l, CubeFace.f)];
    for (final (s1, s2) in slots) {
      if (_isEdgeAtSlot(currentS, s1, s2, cF, cR, p)) {
        if (!_isEdgeSolved(currentS, s1, s2, p)) {
          apply(_remapFor(_parse("U R U' R' U' F' U F"), s1, p));
        } else {
          return [];
        }
        break;
      }
    }
    final top = [CubeFace.f, CubeFace.r, CubeFace.b, CubeFace.l];
    CubeFace? found;
    for (final side in top) {
      if (_isEdgeAtSlot(currentS, CubeFace.u, side, cF, cR, p)) {
        found = side;
        break;
      }
    }
    if (found == null) {
      return moves;
    }
    final phSide = _remapFace(found, p);
    final sideStk = currentS.getFace(phSide)[_getPhysicalEdgeIndex(phSide, p.u)];
    if (sideStk == cF) {
      final turns = _logicalUTurns(found, CubeFace.f);
      if (turns != 0) {
        apply([_remap(CubeMove(CubeFace.u, turns), p)]);
      }
      apply(_remapFor(_parse("U R U' R' U' F' U F"), CubeFace.f, p));
    } else {
      final turns = _logicalUTurns(found, CubeFace.r);
      if (turns != 0) {
        apply([_remap(CubeMove(CubeFace.u, turns), p)]);
      }
      apply(_remapFor(_parse("U' L' U L U F U' F'"), CubeFace.r, p));
    }
    return moves;
  }

  static List<LblStep> _yellowCross(CubeState s, Perspective p) {
    final steps = <LblStep>[];
    var currentS = s;
    int safety = 0;
    while (safety++ < 10) {
      final pu = p.u; final c = currentS.getFace(pu)[4];
      final b = currentS.getFace(pu)[_getPhysicalEdgeIndex(pu, p.b)] == c;
      final l = currentS.getFace(pu)[_getPhysicalEdgeIndex(pu, p.l)] == c;
      final r = currentS.getFace(pu)[_getPhysicalEdgeIndex(pu, p.r)] == c;
      final f = currentS.getFace(pu)[_getPhysicalEdgeIndex(pu, p.f)] == c;
      final count = (b ? 1 : 0) + (l ? 1 : 0) + (r ? 1 : 0) + (f ? 1 : 0);
      if (count == 4) {
        break;
      }
      final moves = <CubeMove>[];
      if (count == 0) {
        moves.addAll(_remapFor(_parse("F R U R' U' F'"), CubeFace.f, p));
      } else if (count == 2) {
        if (l && r) {
          moves.addAll(_remapFor(_parse("F R U R' U' F'"), CubeFace.f, p));
        } else if (f && b) {
          moves.addAll(_remapFor(_parse("F R U R' U' F'"), CubeFace.r, p));
        } else if (b && l) {
          moves.addAll(_remapFor(_parse("F R U R' U' F'"), CubeFace.f, p));
        } else if (l && f) {
          moves.addAll(_remapFor(_parse("F R U R' U' F'"), CubeFace.r, p));
        } else if (f && r) {
          moves.addAll(_remapFor(_parse("F R U R' U' F'"), CubeFace.b, p));
        } else {
          moves.addAll(_remapFor(_parse("F R U R' U' F'"), CubeFace.l, p));
        }
      }
      steps.add(LblStep(stageName: 'CFOP Yellow Cross (Fallback)', moves: moves, description: 'Orienting yellow edges'));
      currentS = currentS.applyMoves(moves);
    }
    return steps;
  }

  static List<LblStep> _alignYellowEdges(CubeState s, Perspective p) {
    final steps = <LblStep>[];
    var currentS = s;
    bool allAligned(CubeState cs) {
      for (final f in [CubeFace.f, CubeFace.r, CubeFace.b, CubeFace.l]) {
        final ph = _remapFace(f, p);
        if (cs.getFace(ph)[_getPhysicalEdgeIndex(ph, p.u)] != cs.getFace(ph)[4]) {
          return false;
        }
      }
      return true;
    }
    int safety = 0;
    while (safety++ < 10 && !allAligned(currentS)) {
      int best = -1;
      for (int t = 0; t < 4; t++) {
        if (allAligned(currentS.applyMoves([_remap(CubeMove(CubeFace.u, t), p)]))) {
          best = t; break;
        }
      }
      if (best != -1) {
        if (best > 0) {
          final m = [_remap(CubeMove(CubeFace.u, best), p)];
          steps.add(LblStep(stageName: 'CFOP Edge Align (Fallback)', moves: m, description: 'Aligning top edges'));
          currentS = currentS.applyMoves(m);
        }
        break;
      }

      bool suneApplied = false;
      for (int turns = 0; turns < 4; turns++) {
        final checkS = currentS.applyMoves([_remap(CubeMove(CubeFace.u, turns), p)]);
        final matched = <CubeFace>[];
        for (final f in [CubeFace.f, CubeFace.r, CubeFace.b, CubeFace.l]) {
          final phF = _remapFace(f, p);
          if (checkS.getFace(phF)[_getPhysicalEdgeIndex(phF, p.u)] == checkS.getFace(phF)[4]) matched.add(f);
        }
        if (matched.length >= 2) {
          if (turns > 0) {
            final uMoves = [_remap(CubeMove(CubeFace.u, turns), p)];
            steps.add(LblStep(stageName: 'CFOP Edge Align (Fallback)', moves: uMoves, description: 'Rotating top to find edge matches'));
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

          final suneMoves = _remapFor(_parse("R U R' U R U2 R'"), frontForSune, p);
          steps.add(LblStep(stageName: 'CFOP Edge Align (Fallback)', moves: suneMoves, algorithmName: 'Sune', description: 'Cycling edges'));
          currentS = currentS.applyMoves(suneMoves);
          suneApplied = true; break;
        }
      }
      if (!suneApplied) {
        final suneMoves = _remapFor(_parse("R U R' U R U2 R'"), CubeFace.f, p);
        steps.add(LblStep(stageName: 'CFOP Edge Align (Fallback)', moves: suneMoves, algorithmName: 'Sune', description: 'Cycling edges'));
        currentS = currentS.applyMoves(suneMoves);
      }
    }
    return steps;
  }

  static List<LblStep> _yellowCorners(CubeState s, Perspective p) {
    final steps = <LblStep>[];
    var currentS = s;
    bool aligned() {
      for (final (f1, f2) in [(CubeFace.f, CubeFace.r), (CubeFace.r, CubeFace.b), (CubeFace.b, CubeFace.l), (CubeFace.l, CubeFace.f)]) {
        if (!_isPieceAtCornerInTargetSlot(currentS, CubeFace.u, f1, f2, p)) return false;
      }
      return true;
    }
    int safety = 0;
    while (safety++ < 20 && !aligned()) {
      CubeFace? pivot;
      for (final (f1, f2) in [(CubeFace.f, CubeFace.r), (CubeFace.r, CubeFace.b), (CubeFace.b, CubeFace.l), (CubeFace.l, CubeFace.f)]) {
        if (_isPieceAtCornerInTargetSlot(currentS, CubeFace.u, f1, f2, p)) { pivot = f1; break; }
      }
      final moves = _remapFor(_parse("U R U' L' U R' U' L"), pivot ?? CubeFace.f, p);
      steps.add(LblStep(stageName: 'CFOP Corner Align (Fallback)', moves: moves, algorithmName: 'Niklas', description: 'Cycling corners'));
      currentS = currentS.applyMoves(moves);
    }
    for (int i = 0; i < 4; i++) {
        final idx = _getPhysicalCornerIndex(p.u, p.f, p.r);
        if (currentS.getFace(p.u)[idx] != currentS.getFace(p.u)[4]) {
            final testCsCw = currentS.applyMoves(_remapFor(_parse("R' D' R D R' D' R D"), CubeFace.f, p));
            final isSolvedCw = testCsCw.getFace(p.u)[idx] == currentS.getFace(p.u)[4];
            final slice = isSolvedCw ? _remapFor(_parse("R' D' R D R' D' R D"), CubeFace.f, p) : _remapFor(_parse("D' R' D R D' R' D R"), CubeFace.f, p);
            steps.add(LblStep(stageName: 'CFOP Corner Align (Fallback)', moves: slice, algorithmName: isSolvedCw ? "R' D' R D x 2" : "D' R' D R x 2", description: 'Orienting corner'));
            currentS = currentS.applyMoves(slice);
        }
        if (i < 3) {
            bool remainsUnsolved = false;
            for (int k = i + 1; k < 4; k++) {
                if (currentS.applyMoves([_remap(CubeMove(CubeFace.u, k - i), p)]).getFace(p.u)[idx] != currentS.getFace(p.u)[4]) { remainsUnsolved = true; break; }
            }
            if (remainsUnsolved) {
                final uMove = [_remap(CubeMove(CubeFace.u, 1), p)];
                steps.add(LblStep(stageName: 'CFOP Corner Align (Fallback)', moves: uMove, description: 'Next corner'));
                currentS = currentS.applyMoves(uMove);
            }
        }
    }
    int finalTurns = 0;
    for (int t = 0; t < 4; t++) {
      final testCS = currentS.applyMoves([_remap(CubeMove(CubeFace.u, t), p)]);
      final tf = _remapFace(CubeFace.f, p);
      if (testCS.getFace(tf)[_getPhysicalEdgeIndex(tf, p.u)] == testCS.getFace(tf)[4]) { finalTurns = t; break; }
    }
    if (finalTurns > 0) {
      final uMove = [_remap(CubeMove(CubeFace.u, finalTurns), p)];
      steps.add(LblStep(stageName: 'CFOP Corner Align (Fallback)', moves: uMove, description: 'Final alignment'));
      currentS = currentS.applyMoves(uMove);
    }
    return steps;
  }

  static bool _isEdgeSolved(CubeState s, CubeFace lf1, CubeFace lf2, Perspective p) {
    final p1 = _remapFace(lf1, p), p2 = _remapFace(lf2, p);
    return s.getFace(p1)[_getPhysicalEdgeIndex(p1, p2)] == s.getFace(p1)[4] && s.getFace(p2)[_getPhysicalEdgeIndex(p2, p1)] == s.getFace(p2)[4];
  }

  static bool _isCornerSolved(CubeState s, CubeFace ld, CubeFace lf, CubeFace lr, Perspective p) {
    final pu = _remapFace(ld, p), pf = _remapFace(lf, p), pr = _remapFace(lr, p);
    return s.getFace(pu)[_getPhysicalCornerIndex(pu, pf, pr)] == s.getFace(pu)[4] && s.getFace(pf)[_getPhysicalCornerIndex(pf, pu, pr)] == s.getFace(pf)[4] && s.getFace(pr)[_getPhysicalCornerIndex(pr, pu, pf)] == s.getFace(pr)[4];
  }

  static Perspective perspectiveForDown(CubeFace down) {
    final up = _opposite(down);
    CubeFace front = (up == CubeFace.u || up == CubeFace.d || up == CubeFace.r) ? CubeFace.f : (up == CubeFace.f ? CubeFace.d : (up == CubeFace.b ? CubeFace.u : CubeFace.f));
    return _perspectiveFromUpFront(up, front);
  }

  static Perspective _perspectiveFromUpFront(CubeFace u, CubeFace f) {
    final d = _opposite(u), b = _opposite(f), r = _cross(u, f), l = _opposite(r);
    return Perspective(u: u, d: d, f: f, b: b, r: r, l: l);
  }

  static CubeFace _opposite(CubeFace f) {
    switch (f) {
      case CubeFace.u: return CubeFace.d; case CubeFace.d: return CubeFace.u;
      case CubeFace.f: return CubeFace.b; case CubeFace.b: return CubeFace.f;
      case CubeFace.r: return CubeFace.l; case CubeFace.l: return CubeFace.r;
      default: return f;
    }
  }

  static CubeFace _cross(CubeFace u, CubeFace f) {
    const vectors = { CubeFace.u: (0, 1, 0), CubeFace.d: (0, -1, 0), CubeFace.r: (1, 0, 0), CubeFace.l: (-1, 0, 0), CubeFace.f: (0, 0, 1), CubeFace.b: (0, 0, -1) };
    final v1 = vectors[u]!, v2 = vectors[f]!;
    final rx = v1.$2 * v2.$3 - v1.$3 * v2.$2, ry = v1.$3 * v2.$1 - v1.$1 * v2.$3, rz = v1.$1 * v2.$2 - v1.$2 * v2.$1;
    for (final entry in vectors.entries) {
      if (entry.value.$1 == rx && entry.value.$2 == ry && entry.value.$3 == rz) {
        return entry.key;
      }
    }
    return CubeFace.r;
  }

  static Perspective perspectiveFlipped(Perspective p) => Perspective(u: p.d, d: p.u, f: p.b, b: p.f, r: p.r, l: p.l);

  static CubeMove _remap(CubeMove m, Perspective p) {
    CubeFace pf;
    switch (m.face) {
      case CubeFace.u: pf = p.u; break; case CubeFace.d: pf = p.d; break;
      case CubeFace.f: pf = p.f; break; case CubeFace.b: pf = p.b; break;
      case CubeFace.r: pf = p.r; break; case CubeFace.l: pf = p.l; break;
      default: pf = m.face; break;
    }
    return CubeMove(pf, m.turns);
  }

  static List<CubeMove> _remapAll(List<CubeMove> moves, Perspective p) => moves.map((m) => _remap(m, p)).toList();

  static List<CubeMove> _remapFor(List<CubeMove> moves, CubeFace logicalFront, Perspective p) {
    final tempP = _perspectiveRotateY(p, logicalFront);
    return _remapAll(moves, tempP);
  }

  static Perspective _perspectiveRotateY(Perspective p, CubeFace logicalFront) {
    if (logicalFront == CubeFace.f) {
      return p;
    }
    final physFront = _remapFace(logicalFront, p);
    final physRight = _cross(p.u, physFront);
    final physLeft = _opposite(physRight);
    final physBack = _opposite(physFront);
    return Perspective(u: p.u, d: p.d, f: physFront, b: physBack, r: physRight, l: physLeft);
  }

  static CubeFace _remapFace(CubeFace f, Perspective p) {
    switch (f) {
      case CubeFace.u: return p.u; case CubeFace.d: return p.d;
      case CubeFace.f: return p.f; case CubeFace.b: return p.b;
      case CubeFace.r: return p.r; case CubeFace.l: return p.l;
      default: return f;
    }
  }

  static CubeFace _logicalFaceFor(CubeFace physical, Perspective p) {
    if (physical == p.u) {
      return CubeFace.u;
    }
    if (physical == p.d) {
      return CubeFace.d;
    }
    if (physical == p.f) {
      return CubeFace.f;
    }
    if (physical == p.b) {
      return CubeFace.b;
    }
    if (physical == p.r) {
      return CubeFace.r;
    }
    if (physical == p.l) {
      return CubeFace.l;
    }
    return CubeFace.u;
  }

  static CubeFace _findCenterFace(CubeState s, CubeColor c) {
    for (final f in CubeFace.physicalFaces) {
      if (s.getFace(f)[4] == c) {
        return f;
      }
    }
    return CubeFace.u;
  }

  static bool _isPieceAtCorner(CubeState s, CubeFace lf1, CubeFace lf2, CubeFace lf3, CubeColor c1, CubeColor c2, CubeColor c3, Perspective p) {
    final p1 = _remapFace(lf1, p), p2 = _remapFace(lf2, p), p3 = _remapFace(lf3, p);
    final colors = {s.getFace(p1)[_getPhysicalCornerIndex(p1, p2, p3)], s.getFace(p2)[_getPhysicalCornerIndex(p2, p1, p3)], s.getFace(p3)[_getPhysicalCornerIndex(p3, p1, p2)]};
    return colors.contains(c1) && colors.contains(c2) && colors.contains(c3);
  }

  static bool _isPieceAtCornerInTargetSlot(CubeState s, CubeFace lu, CubeFace lf, CubeFace lr, Perspective p) {
    final pu = _remapFace(lu, p), pf = _remapFace(lf, p), pr = _remapFace(lr, p);
    return _isPieceAtCorner(s, lu, lf, lr, s.getFace(pu)[4], s.getFace(pf)[4], s.getFace(pr)[4], p);
  }

  static bool _isEdgeAtSlot(CubeState s, CubeFace lf1, CubeFace lf2, CubeColor c1, CubeColor c2, Perspective p) {
    final p1 = _remapFace(lf1, p), p2 = _remapFace(lf2, p);
    final colors = {s.getFace(p1)[_getPhysicalEdgeIndex(p1, p2)], s.getFace(p2)[_getPhysicalEdgeIndex(p2, p1)]};
    return colors.contains(c1) && colors.contains(c2);
  }

  static int _logicalUTurns(CubeFace from, CubeFace to) {
    const cycle = [CubeFace.f, CubeFace.l, CubeFace.b, CubeFace.r];
    final fi = cycle.indexOf(from), ti = cycle.indexOf(to);
    return (fi == -1 || ti == -1) ? 0 : (ti - fi + 4) % 4;
  }

  static int _getPhysicalEdgeIndex(CubeFace f, CubeFace neighbor) {
    for (final (f1, i1, f2, i2) in _allEdges) {
      if (f1 == f && f2 == neighbor) {
        return i1;
      }
      if (f2 == f && f1 == neighbor) {
        return i2;
      }
    }
    return 4;
  }

  static int _getPhysicalCornerIndex(CubeFace f, CubeFace n1, CubeFace n2) {
    final search = {n1, n2};
    for (final (f1, i1, f2, i2, f3, i3) in _allCorners) {
      if (f1 == f && search.contains(f2) && search.contains(f3)) {
        return i1;
      }
      if (f2 == f && search.contains(f1) && search.contains(f3)) {
        return i2;
      }
      if (f3 == f && search.contains(f1) && search.contains(f2)) {
        return i3;
      }
    }
    return 4;
  }

  static const _allEdges = [(CubeFace.u, 7, CubeFace.f, 1), (CubeFace.u, 5, CubeFace.r, 1), (CubeFace.u, 1, CubeFace.b, 1), (CubeFace.u, 3, CubeFace.l, 1), (CubeFace.d, 1, CubeFace.f, 7), (CubeFace.d, 5, CubeFace.r, 7), (CubeFace.d, 7, CubeFace.b, 7), (CubeFace.d, 3, CubeFace.l, 7), (CubeFace.f, 5, CubeFace.r, 3), (CubeFace.f, 3, CubeFace.l, 5), (CubeFace.b, 3, CubeFace.r, 5), (CubeFace.b, 5, CubeFace.l, 3)];
  static const _allCorners = [(CubeFace.u, 6, CubeFace.f, 0, CubeFace.l, 2), (CubeFace.u, 8, CubeFace.r, 0, CubeFace.f, 2), (CubeFace.u, 2, CubeFace.b, 0, CubeFace.r, 2), (CubeFace.u, 0, CubeFace.l, 0, CubeFace.b, 2), (CubeFace.d, 0, CubeFace.l, 8, CubeFace.f, 6), (CubeFace.d, 2, CubeFace.f, 8, CubeFace.r, 6), (CubeFace.d, 8, CubeFace.r, 8, CubeFace.b, 6), (CubeFace.d, 6, CubeFace.b, 8, CubeFace.l, 6)];

  static List<CubeMove> _parse(String s) => s.isEmpty ? [] : s.split(' ').map((m) => CubeMove.parse(m)!).toList();
  static String _cn(CubeColor c) => c.name.toLowerCase();

  static List<LblStep> optimizeSteps(List<LblStep> steps) {
    if (steps.isEmpty) {
      return [];
    }
    var currentSteps = steps.map((s) => LblStep(stageName: s.stageName, moves: optimizeMoves(s.moves), description: s.description, algorithmName: s.algorithmName)).toList();
    return currentSteps.where((s) => s.moves.isNotEmpty).toList();
  }

  static List<CubeMove> optimizeMoves(List<CubeMove> moves) {
    if (moves.isEmpty) {
      return [];
    }
    final result = <CubeMove>[];
    for (final move in moves) {
      if (result.isNotEmpty && result.last.face == move.face) {
        final last = result.removeLast();
        int totalTurns = (last.turns + move.turns) % 4;
        if (totalTurns > 2) {
          totalTurns -= 4;
        }
        if (totalTurns < -1) {
          totalTurns += 4;
        }
        if (totalTurns != 0) {
          result.add(CubeMove(last.face, totalTurns));
        }
      } else {
        result.add(move);
      }
    }
    return result;
  }
}
