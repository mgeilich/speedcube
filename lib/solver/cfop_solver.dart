part of 'lbl_solver.dart';

class CfopSolver {
  /// Solve the cube using CFOP (Cross + F2L + OLL + PLL)
  static LblSolveResult? solve(CubeState initial) {
    var s = initial;
    if (s.isSolved) {
      return LblSolveResult(steps: []);
    }

    final steps = <LblStep>[];
    final whiteFace = LblSolver._findCenterFace(s, CubeColor.white);
    final p = LblSolver.perspectiveFor(whiteFace);

    // 1. Cross
    if (!LblSolver.isCrossSolved(s, p)) {
      final crossSteps = LblSolver._whiteCross(s, p);
      for (final step in crossSteps) {
        s = s.applyMoves(step.moves);
        steps.add(step);
      }
    }

    final p2 = LblSolver.perspectiveFlipped(p);
    
    // 2. F2L
    final s2 = _f2l(s, p2);
    for (final step in s2) {
      s = s.applyMoves(step.moves);
      steps.add(step);
    }

    // 3. OLL
    final s3 = _oll(s, p2);
    for (final step in s3) {
      s = s.applyMoves(step.moves);
      steps.add(step);
    }

    // 4. PLL
    final s4 = _pll(s, p2);
    for (final step in s4) {
      s = s.applyMoves(step.moves);
      steps.add(step);
    }
    
    if (!s.isSolved) {
      final align = LblSolver._alignYellowEdges(s, p2);
      for (final st in align) {
        s = s.applyMoves(st.moves);
      }
      steps.addAll(align);
    }
    if (!s.isSolved) {
      final corners = LblSolver._yellowCorners(s, p2).where((st) => st.stageName == 'Yellow Corners');
      for (final st in corners) {
        s = s.applyMoves(st.moves);
      }
      steps.addAll(corners);
    }

    return LblSolveResult(steps: LblSolver.optimizeSteps(steps));
  }

  static List<LblStep> _f2l(CubeState s, Perspective p) {
    final steps = <LblStep>[];
    var currentS = s;
    final slots = [CubeFace.f, CubeFace.r, CubeFace.b, CubeFace.l];
    
    for (final slotF in slots) {
      final currP = LblSolver._perspectiveRotateY(p, slotF);
      final cF = currentS.getFace(currP.f)[4];
      final cR = currentS.getFace(currP.r)[4];
      
      bool isSlotSolved(CubeState cs) =>
          LblSolver._isCornerSolved(cs, CubeFace.d, CubeFace.f, CubeFace.r, currP) &&
          LblSolver._isEdgeSolved(cs, CubeFace.f, CubeFace.r, currP);

      if (isSlotSolved(currentS)) {
        continue;
      }

      // Try 1-look F2L algorithms (all 16 cases)
      AlgCase? matched; int uTurns = 0;
      final f2lCases = AlgLibrary.f2l;
      
      outer: for (int i = 0; i < 4; i++) {
        final setupMoves = List.filled(i, LblSolver._remap(CubeMove(CubeFace.u, 1), currP));
        final trialS = currentS.applyMoves(setupMoves);
        for (final c in f2lCases) {
          final algoMoves = LblSolver._remapAll(c.algorithmMoves, currP);
          if (isSlotSolved(trialS.applyMoves(algoMoves))) {
            matched = c; uTurns = i; break outer;
          }
        }
      }

      if (matched != null) {
        final setup = uTurns == 0 ? <CubeMove>[] : List.filled(uTurns, LblSolver._remap(CubeMove(CubeFace.u, 1), currP));
        steps.add(LblStep(
          stageName: 'F2L Insertion', 
          algorithmName: matched.name, 
          moves: [...setup, ...LblSolver._remapAll(matched.algorithmMoves, currP)], 
          description: 'Solving ${_cn(cF)}-${_cn(cR)} pair'
        ));
        currentS = currentS.applyMoves(steps.last.moves);
      } else {
        // Fallback to LBL logic for extraction and two-step solving
        if (!LblSolver._isCornerSolved(currentS, CubeFace.d, CubeFace.f, CubeFace.r, currP)) {
          final cornerMoves = LblSolver._solveCornerToD(currentS, currP, cF, cR);
          if (cornerMoves.isNotEmpty) {
            steps.add(LblStep(stageName: 'CFOP F2L', moves: cornerMoves, description: 'Solving ${_cn(cF)}-${_cn(cR)} corner'));
            currentS = currentS.applyMoves(cornerMoves);
          }
        }

        if (!LblSolver._isEdgeSolved(currentS, CubeFace.f, CubeFace.r, currP)) {
          final edgeMoves = LblSolver._solveEdgeToMiddle(currentS, currP, cF, cR);
          if (edgeMoves.isNotEmpty) {
            steps.add(LblStep(stageName: 'CFOP F2L', moves: edgeMoves, description: 'Solving ${_cn(cF)}-${_cn(cR)} edge'));
            currentS = currentS.applyMoves(edgeMoves);
          }
        }
      }
    }
    return steps;
  }

  static String _cn(CubeColor c) => c.name.toLowerCase();

  static List<LblStep> _oll(CubeState s, Perspective p) {
    var currentS = s;
    final steps = <LblStep>[];
    final y = currentS.getFace(p.u)[4];

    bool isOllSolved(CubeState cs) => cs.getFace(p.u).every((stk) => stk == y);
    
    if (!isOllSolved(currentS)) {
      AlgCase? matched; int uTurns = 0;
      final ollCases = AlgLibrary.oll;
      
      outer: for (int i=0; i<4; i++) {
        final setupMoves = List.filled(i, LblSolver._remap(CubeMove(CubeFace.u, 1), p));
        final trialS = currentS.applyMoves(setupMoves);
        for (final c in ollCases) {
          if (isOllSolved(trialS.applyMoves(LblSolver._remapAll(c.algorithmMoves, p)))) {
            matched = c; uTurns = i; break outer;
          }
        }
      }

      if (matched != null) {
        final setup = uTurns == 0 ? <CubeMove>[] : [LblSolver._remap(CubeMove(CubeFace.u, uTurns), p)];
        steps.add(LblStep(
          stageName: 'OLL Orientation', 
          algorithmName: matched.name, 
          moves: [...setup, ...LblSolver._remapAll(matched.algorithmMoves, p)], 
          description: 'Orienting the top layer'
        ));
      } else {
        if (!isCrossOriented(currentS, y, p)) {
          final crossSteps = LblSolver._yellowCross(currentS, p);
          steps.addAll(crossSteps);
          for (final step in crossSteps) {
            currentS = currentS.applyMoves(step.moves);
          }
        }
        AlgCase? matched2; int uTurns2 = 0;
        final crossOllCases = AlgLibrary.oll.where((c) => c.subcategory == 'Cross' || c.id.startsWith('oll2')).toList();
        outer2: for (int i=0; i<4; i++) {
          final setup = List.filled(i, LblSolver._remap(CubeMove(CubeFace.u, 1), p));
          final trialS = currentS.applyMoves(setup);
          for (final c in crossOllCases) {
            if (isOllSolved(trialS.applyMoves(LblSolver._remapAll(c.algorithmMoves, p)))) {
              matched2 = c; uTurns2 = i; break outer2;
            }
          }
        }
        if (matched2 != null) {
          final setup = uTurns2 == 0 ? <CubeMove>[] : [LblSolver._remap(CubeMove(CubeFace.u, uTurns2), p)];
          steps.add(LblStep(
            stageName: 'OLL Orientation', 
            algorithmName: matched2.name, 
            moves: [...setup, ...LblSolver._remapAll(matched2.algorithmMoves, p)], 
            description: 'Orienting top corners'
          ));
        } else {
          steps.addAll(LblSolver._yellowCorners(currentS, p).where((st) => st.stageName == 'Yellow Corners'));
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

    // Correctly identify sticker indices for the row adjacent to current p.u
    List<CubeColor> getStickersAdjacentToU(CubeState cs, CubeFace f) {
        final c1Idx = LblSolver._getPhysicalCornerIndex(f, p.u, LblSolver._perspectiveRotateY(p, f).l);
        final eIdx = LblSolver._getPhysicalEdgeIndex(f, p.u);
        final c2Idx = LblSolver._getPhysicalCornerIndex(f, p.u, LblSolver._perspectiveRotateY(p, f).r);
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
      final setup = i == 0 ? <CubeMove>[] : [LblSolver._remap(CubeMove(CubeFace.u, i), p)];
      final trialS = currentS.applyMoves(setup);
      for (final c in AlgLibrary.pll) {
        final algoMoves = LblSolver._remapAll(c.algorithmMoves, p);
        final nextS = trialS.applyMoves(algoMoves);
        for (int k=0; k<4; k++) {
          final lastMove = k == 0 ? <CubeMove>[] : [LblSolver._remap(CubeMove(CubeFace.u, k), p)];
          if (isSideSolved(nextS.applyMoves(lastMove))) {
            matched = c; uTurns = i; finalAlign = k; break outer;
          }
        }
      }
    }

    if (matched != null && matched.id != 'pll_solved') {
      final setup = uTurns == 0 ? <CubeMove>[] : [LblSolver._remap(CubeMove(CubeFace.u, uTurns), p)];
      final finalize = finalAlign == 0 ? <CubeMove>[] : [LblSolver._remap(CubeMove(CubeFace.u, finalAlign), p)];
      steps.add(LblStep(
        stageName: 'PLL Permutation', 
        algorithmName: matched.name, 
        moves: [...setup, ...LblSolver._remapAll(matched.algorithmMoves, p), ...finalize], 
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
          final setup = i == 0 ? <CubeMove>[] : [LblSolver._remap(CubeMove(CubeFace.u, i), p)];
          final trialS = currentS.applyMoves(setup);
          for (final c in cornerCases) {
            if (cornersCorrect(trialS.applyMoves(LblSolver._remapAll(c.algorithmMoves, p)))) {
              cMatched = c; cuTurns = i; break outer2;
            }
          }
        }
        if (cMatched != null) {
          final setup = cuTurns == 0 ? <CubeMove>[] : [LblSolver._remap(CubeMove(CubeFace.u, cuTurns), p)];
          steps.add(LblStep(
            stageName: 'PLL Corners', 
            algorithmName: cMatched.name, 
            moves: [...setup, ...LblSolver._remapAll(cMatched.algorithmMoves, p)], 
            description: 'Permuting corners'
          ));
          currentS = currentS.applyMoves(steps.last.moves);
        }
      }

      int alignTurns = 0;
      for (int i=0; i<4; i++) {
        final move = LblSolver._remap(CubeMove(CubeFace.u, i), p);
        final testS = currentS.applyMoves([move]);
        if (getStickersAdjacentToU(testS, p.f)[0] == testS.getFace(p.f)[4]) {
          alignTurns = i; break;
        }
      }
      if (alignTurns != 0) {
        final move = LblSolver._remap(CubeMove(CubeFace.u, alignTurns), p);
        steps.add(LblStep(stageName: 'PLL Align', moves: [move], description: 'Aligning corners'));
        currentS = currentS.applyMoves([move]);
      }

      if (!isSideSolved(currentS)) {
        AlgCase? eMatched; int euTurns = 0;
        final edgeCases = AlgLibrary.pll.where((c) => c.subcategory == 'Edges Only').toList();
        outer3: for (int i=0; i<4; i++) {
          final setup = i == 0 ? <CubeMove>[] : [LblSolver._remap(CubeMove(CubeFace.u, i), p)];
          final trialS = currentS.applyMoves(setup);
          for (final c in edgeCases) {
            if (isSideSolved(trialS.applyMoves(LblSolver._remapAll(c.algorithmMoves, p)))) {
              eMatched = c; euTurns = i; break outer3;
            }
          }
        }
        if (eMatched != null) {
          final setup = euTurns == 0 ? <CubeMove>[] : [LblSolver._remap(CubeMove(CubeFace.u, euTurns), p)];
          steps.add(LblStep(
            stageName: 'PLL Edges', 
            algorithmName: eMatched.name, 
            moves: [...setup, ...LblSolver._remapAll(eMatched.algorithmMoves, p)], 
            description: 'Permuting edges'
          ));
          currentS = currentS.applyMoves(steps.last.moves);
        } else {
          steps.addAll(LblSolver._alignYellowEdges(currentS, p));
          currentS = currentS.applyMoves(steps.last.moves);
        }
      }
    }

    int finalTurns = 0;
    for (int i=0; i<4; i++) {
      final move = LblSolver._remap(CubeMove(CubeFace.u, i), p);
      if (currentS.applyMoves([move]).isSolved) {
        finalTurns = i; break;
      }
    }
    if (finalTurns != 0) {
      steps.add(LblStep(stageName: 'Final Adjust', moves: [LblSolver._remap(CubeMove(CubeFace.u, finalTurns), p)], description: 'Final turn to solve'));
    }

    return steps;
  }
}
