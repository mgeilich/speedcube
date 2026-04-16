import '../models/cube_state.dart';
import '../models/cube_move.dart';
import '../models/alg_library.dart';
import '../models/solve_result.dart';

/// A solver that implements the ZZ method (EOLine, ZZ-F2L, LL).
class ZzSolver {
  
  /// Solve the cube using the ZZ method.
  static LblSolveResult? solve(CubeState initial) {
    if (initial.isSolved) return const LblSolveResult(steps: []);

    // 1. Orientation Scoring
    final orientations = _generateAll24Rotations();
    orientations.sort((a, b) => _scoreZzOrientation(initial.applyMoves(b)).compareTo(_scoreZzOrientation(initial.applyMoves(a))));
    
    // Pass 1: Try top 6 orientations with generous budget
    for (int i = 0; i < 6 && i < orientations.length; i++) {
        final rotation = orientations[i];
        final oriented = initial.applyMoves(rotation);
        final result = _solveFromOrientation(oriented, rotation);
        if (result != null) return result;
    }


    return null;
  }

  static int _scoreZzOrientation(CubeState s) {
    int score = 0;
    final cU = s.getFace(CubeFace.u)[4];
    final cD = s.getFace(CubeFace.d)[4];
    final cF = s.getFace(CubeFace.f)[4];
    final cB = s.getFace(CubeFace.b)[4];

    // Count oriented edges (crucial for EOLine)
    for (final edge in _allEdges) {
      if (_isEdgeOriented(s, edge, cU, cD, cF, cB)) score += 2;
    }
    // Favor cases where DF or DB are already close to home
    // Check DF (D1 and F7)
    if (s.getFace(CubeFace.d)[1] == cD && s.getFace(CubeFace.f)[7] == cF) score += 5;
    // Check DB (D7 and B7)
    if (s.getFace(CubeFace.d)[7] == cD && s.getFace(CubeFace.b)[7] == cB) score += 5;

    // Favor "True ZZ" orientations (White or Yellow on top/bottom)
    if (cD == CubeColor.white || cD == CubeColor.yellow) score += 30;

    return score;
  }


  static LblSolveResult? _solveFromOrientation(CubeState oriented, List<CubeMove> preMoves) {
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
    final eoMoves = _findEO(s);
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
    final lineMoves = _findLine(s);
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
    final lbSteps = _solveBlock(s, isLeft: true);
    if (lbSteps == null) return null;
    steps.addAll(lbSteps);
    s = s.applyMoves(lbSteps.expand((st) => st.moves).toList());

    // Stage 3: Right Block
    // When solving Right Block, we must preserve the Left Block
    final rbSteps = _solveBlock(s, isLeft: false, preserveOtherBlock: true);
    if (rbSteps == null) return null;
    steps.addAll(rbSteps);
    s = s.applyMoves(rbSteps.expand((st) => st.moves).toList());

    // Stage 4: Last Layer
    final llSteps = _solveLL(s);
    if (llSteps == null) return null;
    steps.addAll(llSteps);



    return LblSolveResult(steps: _optimizeSteps(steps));
  }



  // --- STAGE 1: EOLine ---

  /// Finds moves to orient all edges.
  static List<CubeMove>? _findEO(CubeState s) {
    if (_isEOComplete(s)) return [];

    final queue = <_SearchNode>[_SearchNode(s, null, null)];
    final visited = {s.hashCode};
    int head = 0;
    int nodeCount = 0;

    while (head < queue.length) {
      if (nodeCount++ > 150000) return null;

      final node = queue[head++];
      if (node.depth >= 10) continue; 

      for (final move in CubeMove.physicalMoves) {
        if (node.move?.face == move.face) continue;

        final nextState = node.state.applyMove(move);
        if (_isEOComplete(nextState)) {
          return _reconstructMoves(node, move);
        }
        if (!visited.contains(nextState.hashCode)) {
          visited.add(nextState.hashCode);
          queue.add(_SearchNode(nextState, move, node));
        }
      }
    }
    return null;
  }

  /// Finds moves to solve DF and DB while preserving EO.
  static List<CubeMove>? _findLine(CubeState s) {

    final cD = s.getFace(CubeFace.d)[4];
    final cF = s.getFace(CubeFace.f)[4];
    final cB = s.getFace(CubeFace.b)[4];

    if (_isLineSolved(s, cD, cF, cB)) return [];

    // Restricted move set to preserve EO: <U, D, R, L, F2, B2>
    final lineMoves = [
      CubeMove(CubeFace.u, 1), CubeMove(CubeFace.u, -1), CubeMove(CubeFace.u, 2),
      CubeMove(CubeFace.d, 1), CubeMove(CubeFace.d, -1), CubeMove(CubeFace.d, 2),
      CubeMove(CubeFace.r, 1), CubeMove(CubeFace.r, -1), CubeMove(CubeFace.r, 2),
      CubeMove(CubeFace.l, 1), CubeMove(CubeFace.l, -1), CubeMove(CubeFace.l, 2),
      CubeMove(CubeFace.f, 2), CubeMove(CubeFace.b, 2),
    ];

    final queue = <_SearchNode>[_SearchNode(s, null, null)];
    final visited = {s.hashCode};
    int head = 0;
    int nodeCount = 0;

    while (head < queue.length) {
      if (nodeCount++ > 200000) return null;

      final node = queue[head++];
      if (node.depth >= 12) continue; 

      for (final move in lineMoves) {
        if (node.move?.face == move.face) continue;

        final nextState = node.state.applyMove(move);
        if (_isLineSolved(nextState, cD, cF, cB)) {
          return _reconstructMoves(node, move);
        }
        if (!visited.contains(nextState.hashCode)) {
          visited.add(nextState.hashCode);
          queue.add(_SearchNode(nextState, move, node));
        }
      }
    }
    return null;
  }

  static bool _isEOComplete(CubeState s) {
    final cU = s.getFace(CubeFace.u)[4];
    final cD = s.getFace(CubeFace.d)[4];
    final cF = s.getFace(CubeFace.f)[4];
    final cB = s.getFace(CubeFace.b)[4];
    for (final edge in _allEdges) {
      if (!_isEdgeOriented(s, edge, cU, cD, cF, cB)) return false;
    }
    return true;
  }

  static bool _isLineSolved(CubeState s, CubeColor cD, CubeColor cF, CubeColor cB) {
    // DF and DB must be solved
    return (s.getFace(CubeFace.d)[1] == cD && s.getFace(CubeFace.f)[7] == cF) &&
           (s.getFace(CubeFace.d)[7] == cD && s.getFace(CubeFace.b)[7] == cB);
  }


  /// Check if an edge is oriented according to ZZ standards.
  static bool _isEdgeOriented(CubeState s, (CubeFace, int, CubeFace, int) edge, CubeColor cU, CubeColor cD, CubeColor cF, CubeColor cB) {
    final f1 = edge.$1;
    final f2 = edge.$3;
    final color1 = s.getFace(f1)[edge.$2];
    final color2 = s.getFace(f2)[edge.$4];

    bool isUd(CubeColor c) => c == cU || c == cD;
    bool isFb(CubeColor c) => c == cF || c == cB;

    // 1. Identify primary sticker
    CubeFace primaryFace;
    
    if (isUd(color1)) {
      primaryFace = f1;
    } else if (isUd(color2)) {
      primaryFace = f2;
    } else if (isFb(color1)) {
      primaryFace = f1;
    } else {
      primaryFace = f2;
    }

    // 2. Orientation check
    // Good if on U or D.
    if (primaryFace == CubeFace.u || primaryFace == CubeFace.d) return true;
    
    // Good if on F or B AND the edge is not on the U/D face.
    if (primaryFace == CubeFace.f || primaryFace == CubeFace.b) {
      if (f1 != CubeFace.u && f1 != CubeFace.d && f2 != CubeFace.u && f2 != CubeFace.d) {
        return true;
      }
    }
    
    // Otherwise it's Bad.
    return false;
  }

  // --- STAGE 2 & 3: Block Building ---

  static List<LblStep>? _solveBlock(CubeState initial, {required bool isLeft, bool preserveOtherBlock = false}) {
    final steps = <LblStep>[];
    var current = initial;
    
    final stageName = isLeft ? 'Stage 2: Left Block' : 'Stage 3: Right Block';
    final sideFace = isLeft ? CubeFace.l : CubeFace.r;
    final sideColor = initial.getFace(sideFace)[4];
    final bottomColor = initial.getFace(CubeFace.d)[4];
    final frontColor = initial.getFace(CubeFace.f)[4];
    final backColor = initial.getFace(CubeFace.b)[4];

    final tasks = isLeft ? [
      _Task('DL Edge', (s) => _isEdgeAt(s, CubeFace.d, 3, CubeFace.l, 7, bottomColor, sideColor)),
      _Task('Front Square', (s) => _isEdgeAt(s, CubeFace.f, 3, CubeFace.l, 5, frontColor, sideColor) && 
                                   _isCornerAt(s, CubeFace.d, 0, CubeFace.f, 6, CubeFace.l, 8, bottomColor, frontColor, sideColor)),
      _Task('Back Square', (s) => _isEdgeAt(s, CubeFace.b, 5, CubeFace.l, 3, backColor, sideColor) && 
                                  _isCornerAt(s, CubeFace.d, 6, CubeFace.b, 8, CubeFace.l, 6, bottomColor, backColor, sideColor)),
    ] : [
      _Task('DR Edge', (s) => _isEdgeAt(s, CubeFace.d, 5, CubeFace.r, 7, bottomColor, sideColor)),
      _Task('Front Square', (s) => _isEdgeAt(s, CubeFace.f, 5, CubeFace.r, 3, frontColor, sideColor) && 
                                   _isCornerAt(s, CubeFace.d, 2, CubeFace.f, 8, CubeFace.r, 6, bottomColor, frontColor, sideColor)),
      _Task('Back Square', (s) => _isEdgeAt(s, CubeFace.b, 3, CubeFace.r, 5, backColor, sideColor) && 
                                  _isCornerAt(s, CubeFace.d, 8, CubeFace.b, 6, CubeFace.r, 8, bottomColor, backColor, sideColor)),
    ];

    final solvedTasks = <bool Function(CubeState)>[];
    if (preserveOtherBlock) {
       // Add a task that checks the ENTIRITY of the other block.
       // For ZZ, if we are solving Right, we must preserve Left.

       final otherFrontColor = initial.getFace(CubeFace.f)[4];

       final otherBackColor = initial.getFace(CubeFace.b)[4];
       
       solvedTasks.add((s) => 
         _isEdgeAt(s, CubeFace.d, 3, CubeFace.l, 7, bottomColor, initial.getFace(CubeFace.l)[4]) &&
         _isEdgeAt(s, CubeFace.f, 3, CubeFace.l, 5, otherFrontColor, initial.getFace(CubeFace.l)[4]) &&
         _isCornerAt(s, CubeFace.d, 0, CubeFace.f, 6, CubeFace.l, 8, bottomColor, otherFrontColor, initial.getFace(CubeFace.l)[4]) &&
         _isEdgeAt(s, CubeFace.b, 5, CubeFace.l, 3, otherBackColor, initial.getFace(CubeFace.l)[4]) &&
         _isCornerAt(s, CubeFace.d, 6, CubeFace.b, 8, CubeFace.l, 6, bottomColor, otherBackColor, initial.getFace(CubeFace.l)[4])
       );
    }

    for (final task in tasks) {

      if (task.isSolved(current)) {
        solvedTasks.add(task.isSolved);
        continue;
      }
      final step = _searchForPiece(current, initial, stageName, task.name, task.isSolved, solvedTasks);
      if (step == null) return null;
      steps.add(step);
      current = current.applyMoves(step.moves);
      solvedTasks.add(task.isSolved);
    }


    return steps;
  }

  static LblStep? _searchForPiece(CubeState current, CubeState initial, String stage, String pieceName, bool Function(CubeState) isSolved, List<bool Function(CubeState)> mustStaySolved) {

    final cD = current.getFace(CubeFace.d)[4];
    final cF = current.getFace(CubeFace.f)[4];
    final cB = current.getFace(CubeFace.b)[4];

    final queue = <_SearchNode>[_SearchNode(current, null, null)];
    final visited = {current.hashCode};
    int head = 0;
    int nodeCount = 0;
    const maxNodes = 60000;
    
    // Restricted moves for ZZ F2L: <U, L, R>
    final moves = [
      CubeMove(CubeFace.u, 1), CubeMove(CubeFace.u, -1), CubeMove(CubeFace.u, 2),
      CubeMove(CubeFace.l, 1), CubeMove(CubeFace.l, -1), CubeMove(CubeFace.l, 2),
      CubeMove(CubeFace.r, 1), CubeMove(CubeFace.r, -1), CubeMove(CubeFace.r, 2),
    ];

    while (head < queue.length) {
      if (nodeCount++ > maxNodes) return null;
      final node = queue[head++];
      if (node.depth >= 7) continue;
      
      for (final move in moves) {
        if (node.move?.face == move.face) continue;
        
        final nextState = node.state.applyMove(move);
        // Ensure we don't break EO, Line, or previously solved pieces in this block
        if (isSolved(nextState) && _isEOComplete(nextState) && _isLineSolved(nextState, cD, cF, cB)) {
          bool preservesAll = true;
          for (final check in mustStaySolved) {
            if (!check(nextState)) {
              preservesAll = false;
              break;
            }
          }
          
          if (preservesAll) {
            return LblStep(
              stageName: stage,
              moves: _reconstructMoves(node, move),
              description: 'Solving the $pieceName.',
            );
          }
        }


        
        if (!visited.contains(nextState.hashCode)) {
          visited.add(nextState.hashCode);
          queue.add(_SearchNode(nextState, move, node));
        }
      }
    }
    return null;
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
        steps.add(LblStep(
          stageName: 'Stage 4: Last Layer',
          algorithmName: 'PLL: ${matched.name}',
          moves: [...setup, ...matched.algorithmMoves, ...align],
          description: 'Permuting everything to finish the solve.',
        ));
      }
    }

    return steps;
  }

  // --- HELPERS ---

  static bool _isEdgeAt(CubeState s, CubeFace f1, int i1, CubeFace f2, int i2, CubeColor c1, CubeColor c2) {
    return s.getFace(f1)[i1] == c1 && s.getFace(f2)[i2] == c2;
  }

  static bool _isCornerAt(CubeState s, CubeFace f1, int i1, CubeFace f2, int i2, CubeFace f3, int i3, CubeColor c1, CubeColor c2, CubeColor c3) {
    return s.getFace(f1)[i1] == c1 && s.getFace(f2)[i2] == c2 && s.getFace(f3)[i3] == c3;
  }

  static List<LblStep> _optimizeSteps(List<LblStep> steps) {
    if (steps.isEmpty) return [];

    // 1. Flatten into (Move, OriginalStepIndex)
    final flatMoves = <({CubeMove move, int stepIndex})>[];
    for (int i = 0; i < steps.length; i++) {
      for (final m in steps[i].moves) {
        flatMoves.add((move: m, stepIndex: i));
      }
    }

    // 2. Optimize the flat list while preserving the earliest step index
    final optimizedFlat = <({CubeMove move, int stepIndex})>[];
    for (final ms in flatMoves) {
      if (optimizedFlat.isEmpty) {
        final turns = (ms.move.turns % 4 + 4) % 4;
        if (turns != 0) {
          optimizedFlat.add((
            move: turns == ms.move.turns ? ms.move : CubeMove(ms.move.face, turns, ms.move.isWide),
            stepIndex: ms.stepIndex
          ));
        }
        continue;
      }

      final last = optimizedFlat.last;
      if (last.move.face == ms.move.face && last.move.isWide == ms.move.isWide) {
        optimizedFlat.removeLast();
        int totalTurns = (last.move.turns + ms.move.turns) % 4;
        if (totalTurns < 0) totalTurns += 4;

        if (totalTurns != 0) {
          // Keep the earliest step index to preserve logical flow
          optimizedFlat.add((
            move: CubeMove(ms.move.face, totalTurns == 3 ? -1 : totalTurns, ms.move.isWide),
            stepIndex: last.stepIndex
          ));
        }
        // If totalTurns == 0, they cancel out.
      } else {
        final turns = (ms.move.turns % 4 + 4) % 4;
        if (turns != 0) {
          optimizedFlat.add((
            move: turns == ms.move.turns ? ms.move : CubeMove(ms.move.face, turns, ms.move.isWide),
            stepIndex: ms.stepIndex
          ));
        }
      }
    }

    // 3. Group back into steps
    final newSteps = <LblStep>[];
    for (int i = 0; i < steps.length; i++) {
      final stepMoves = optimizedFlat
          .where((ms) => ms.stepIndex == i)
          .map((ms) => ms.move)
          .toList();
      
      if (stepMoves.isNotEmpty) {
        newSteps.add(LblStep(
          stageName: steps[i].stageName,
          moves: stepMoves,
          description: steps[i].description,
          algorithmName: steps[i].algorithmName,
        ));
      }
    }

    return newSteps;
  }

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

  static const _allEdges = [
    (CubeFace.u, 1, CubeFace.b, 1), (CubeFace.u, 3, CubeFace.l, 1), (CubeFace.u, 5, CubeFace.r, 1), (CubeFace.u, 7, CubeFace.f, 1),
    (CubeFace.d, 1, CubeFace.f, 7), (CubeFace.d, 7, CubeFace.b, 7), (CubeFace.d, 3, CubeFace.l, 7), (CubeFace.d, 5, CubeFace.r, 7),
    (CubeFace.f, 3, CubeFace.l, 5), (CubeFace.f, 5, CubeFace.r, 3), (CubeFace.b, 3, CubeFace.r, 5), (CubeFace.b, 5, CubeFace.l, 3)
  ];
}

class _SearchNode {
  final CubeState state;
  final CubeMove? move;
  final _SearchNode? parent;
  final int depth;

  _SearchNode(this.state, this.move, this.parent) : depth = (parent?.depth ?? -1) + 1;
}

List<CubeMove> _reconstructMoves(_SearchNode node, CubeMove lastMove) {
  final res = <CubeMove>[lastMove];
  _SearchNode? curr = node;
  while (curr?.move != null) {
    res.insert(0, curr!.move!);
    curr = curr.parent;
  }
  return res;
}

class _Task {
  final String name;
  final bool Function(CubeState) isSolved;
  _Task(this.name, this.isSolved);
}
