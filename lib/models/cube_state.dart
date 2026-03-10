import 'dart:math';
import 'cube_move.dart';

/// Represents the colors on the cube
enum CubeColor { white, yellow, green, blue, red, orange }

/// Represents the complete state of a puzzle cube.
///
/// The cube is represented as 6 faces, each with 9 stickers.
/// Sticker indices on each face (looking at the face):
///   0 1 2
///   3 4 5
///   6 7 8
///
/// Face orientation (standard orientation):
/// - U (Up/White): top face
/// - D (Down/Yellow): bottom face
/// - F (Front/Green): front face
/// - B (Back/Blue): back face
/// - R (Right/Red): right face
/// - L (Left/Orange): left face
class CubeState {
  // Each face has 9 stickers, indexed 0-8
  final List<CubeColor> u; // Up face (white when solved)
  final List<CubeColor> d; // Down face (yellow when solved)
  final List<CubeColor> f; // Front face (green when solved)
  final List<CubeColor> b; // Back face (blue when solved)
  final List<CubeColor> r; // Right face (red when solved)
  final List<CubeColor> l; // Left face (orange when solved)

  CubeState._({
    required this.u,
    required this.d,
    required this.f,
    required this.b,
    required this.r,
    required this.l,
  });

  factory CubeState.fromFaces({
    required List<CubeColor> u,
    required List<CubeColor> d,
    required List<CubeColor> f,
    required List<CubeColor> b,
    required List<CubeColor> r,
    required List<CubeColor> l,
  }) {
    return CubeState._(u: u, d: d, f: f, b: b, r: r, l: l);
  }

  /// Create a solved cube (White on top)
  factory CubeState.solved() {
    return CubeState._(
      u: List.filled(9, CubeColor.white),
      d: List.filled(9, CubeColor.yellow),
      f: List.filled(9, CubeColor.green),
      b: List.filled(9, CubeColor.blue),
      r: List.filled(9, CubeColor.red),
      l: List.filled(9, CubeColor.orange),
    );
  }

  /// Create a solved cube with Yellow on top (standard for Last Layer diagrams)
  factory CubeState.yellowTopSolved() {
    return CubeState._(
      u: List.filled(9, CubeColor.yellow),
      d: List.filled(9, CubeColor.white),
      f: List.filled(9, CubeColor.green),
      b: List.filled(9, CubeColor.blue),
      r: List.filled(9, CubeColor.red),
      l: List.filled(9, CubeColor.orange),
    );
  }

  /// Create a deep copy
  CubeState clone() {
    return CubeState._(
      u: List.from(u),
      d: List.from(d),
      f: List.from(f),
      b: List.from(b),
      r: List.from(r),
      l: List.from(l),
    );
  }

  /// Check if the cube is solved
  bool get isSolved {
    bool faceIsSolved(List<CubeColor> face) {
      final color = face[4]; // Center determines the face color
      return face.every((c) => c == color);
    }

    return faceIsSolved(u) &&
        faceIsSolved(d) &&
        faceIsSolved(f) &&
        faceIsSolved(b) &&
        faceIsSolved(r) &&
        faceIsSolved(l);
  }

  /// Get all stickers as a single list
  List<CubeColor> get allStickers => [...u, ...d, ...f, ...b, ...r, ...l];

  /// Apply a move and return a new state
  CubeState applyMove(CubeMove move) {
    final state = clone();

    // Determine number of clockwise quarter turns
    int turns = move.turns;
    if (turns == -1) turns = 3; // Counter-clockwise = 3 clockwise
    if (turns == 2) turns = 2;

    for (int i = 0; i < turns; i++) {
      state._applyQuarterTurn(move.face);
    }

    return state;
  }

  /// Apply multiple moves
  CubeState applyMoves(List<CubeMove> moves) {
    CubeState state = this;
    for (final move in moves) {
      state = state.applyMove(move);
    }
    return state;
  }

  /// Generate a random scramble
  static List<CubeMove> generateScramble([int length = 20]) {
    final random = Random();
    final moves = <CubeMove>[];
    CubeFace? lastFace;

    while (moves.length < length) {
      final move =
          CubeMove.singleMoves[random.nextInt(CubeMove.singleMoves.length)];
      // Avoid consecutive moves on the same face
      if (move.face != lastFace) {
        moves.add(move);
        lastFace = move.face;
      }
    }

    return moves;
  }

  /// Apply a clockwise quarter turn to the specified face
  void _applyQuarterTurn(CubeFace face) {
    switch (face) {
      case CubeFace.u:
        _rotateFaceClockwise(u);
        _cycleEdges(
          f,
          [0, 1, 2],
          l,
          [0, 1, 2],
          b,
          [0, 1, 2],
          r,
          [0, 1, 2],
        );
        break;
      case CubeFace.d:
        _rotateFaceClockwise(d);
        _cycleEdges(
          f,
          [6, 7, 8],
          r,
          [6, 7, 8],
          b,
          [6, 7, 8],
          l,
          [6, 7, 8],
        );
        break;
      case CubeFace.f:
        _rotateFaceClockwise(f);
        _cycleEdgesComplex(
          u,
          [6, 7, 8],
          r,
          [0, 3, 6],
          d,
          [2, 1, 0],
          l,
          [8, 5, 2],
        );
        break;
      case CubeFace.b:
        _rotateFaceClockwise(b);
        _cycleEdgesComplex(
          u,
          [2, 1, 0],
          l,
          [0, 3, 6],
          d,
          [6, 7, 8],
          r,
          [8, 5, 2],
        );
        break;
      case CubeFace.r:
        _rotateFaceClockwise(r);
        _cycleEdgesComplex(
          u,
          [2, 5, 8],
          b,
          [6, 3, 0],
          d,
          [2, 5, 8],
          f,
          [2, 5, 8],
        );
        break;
      case CubeFace.l:
        _rotateFaceClockwise(l);
        _cycleEdgesComplex(
          u,
          [0, 3, 6],
          f,
          [0, 3, 6],
          d,
          [0, 3, 6],
          b,
          [8, 5, 2],
        );
        break;
    }
  }

  /// Rotate a face 90° clockwise (mutates the list)
  void _rotateFaceClockwise(List<CubeColor> face) {
    final temp = List<CubeColor>.from(face);
    face[0] = temp[6];
    face[1] = temp[3];
    face[2] = temp[0];
    face[3] = temp[7];
    face[4] = temp[4];
    face[5] = temp[1];
    face[6] = temp[8];
    face[7] = temp[5];
    face[8] = temp[2];
  }

  /// Rotate a face 90° counter-clockwise (mutates the list)
  void _rotateFaceCounterClockwise(List<CubeColor> face) {
    final temp = List<CubeColor>.from(face);
    face[0] = temp[2];
    face[1] = temp[5];
    face[2] = temp[8];
    face[3] = temp[1];
    face[4] = temp[4];
    face[5] = temp[7];
    face[6] = temp[0];
    face[7] = temp[3];
    face[8] = temp[6];
  }

  /// Rotate a face 180° (mutates the list)
  void _rotateFace180(List<CubeColor> face) {
    final temp = List<CubeColor>.from(face);
    face[0] = temp[8];
    face[1] = temp[7];
    face[2] = temp[6];
    face[3] = temp[5];
    face[4] = temp[4];
    face[5] = temp[3];
    face[6] = temp[2];
    face[7] = temp[1];
    face[8] = temp[0];
  }

  /// Cycle edge stickers between 4 faces (same indices)
  void _cycleEdges(
    List<CubeColor> p1,
    List<int> i1,
    List<CubeColor> p2,
    List<int> i2,
    List<CubeColor> p3,
    List<int> i3,
    List<CubeColor> p4,
    List<int> i4,
  ) {
    for (int i = 0; i < 3; i++) {
      final temp = p1[i1[i]];
      p1[i1[i]] = p4[i4[i]];
      p4[i4[i]] = p3[i3[i]];
      p3[i3[i]] = p2[i2[i]];
      p2[i2[i]] = temp;
    }
  }

  /// Cycle edge stickers with different indices per face
  void _cycleEdgesComplex(
    List<CubeColor> p1,
    List<int> i1,
    List<CubeColor> p2,
    List<int> i2,
    List<CubeColor> p3,
    List<int> i3,
    List<CubeColor> p4,
    List<int> i4,
  ) {
    for (int i = 0; i < 3; i++) {
      final temp = p1[i1[i]];
      p1[i1[i]] = p4[i4[i]];
      p4[i4[i]] = p3[i3[i]];
      p3[i3[i]] = p2[i2[i]];
      p2[i2[i]] = temp;
    }
  }

  /// Get face by enum
  List<CubeColor> getFace(CubeFace face) {
    switch (face) {
      case CubeFace.u:
        return u;
      case CubeFace.d:
        return d;
      case CubeFace.f:
        return f;
      case CubeFace.b:
        return b;
      case CubeFace.r:
        return r;
      case CubeFace.l:
        return l;
    }
  }

  /// Given a sticker at [face][index], return where it ends up after [move].
  /// Handles multi-turn moves (CW, CCW, 180°).
  MapEntry<CubeFace, int> stickerAfterMove(
      CubeFace face, int index, CubeMove move) {
    int turns = move.turns;
    if (turns == -1) turns = 3;
    if (turns == 2) turns = 2;

    var result = MapEntry(face, index);
    for (int i = 0; i < turns; i++) {
      result = _stickerAfterQuarterTurn(result.key, result.value, move.face);
    }
    return result;
  }

  /// Maps a sticker through one clockwise quarter turn of [moveFace].
  MapEntry<CubeFace, int> _stickerAfterQuarterTurn(
      CubeFace face, int index, CubeFace moveFace) {
    // CW face rotation permutation: old index -> new index
    // 0->2, 1->5, 2->8, 3->1, 4->4, 5->7, 6->0, 7->3, 8->6
    const cwFace = [2, 5, 8, 1, 4, 7, 0, 3, 6];

    // Edge cycles for each move (p1->p2->p3->p4->p1 clockwise)
    // Each entry: [face, indices[3]]
    // The cycle direction: sticker on p1[i] goes to p2[i], p2->p3, p3->p4, p4->p1
    // So: if sticker is on p1 at i1[k], it moves to p2 at i2[k]
    //     if on p2 at i2[k], moves to p3 at i3[k], etc.

    // For each move, define the 4-face edge cycle:
    // (face1, indices1, face2, indices2, face3, indices3, face4, indices4)
    // Cycle: face1[i] <- face4[i], face4[i] <- face3[i], etc.
    // So sticker at face1[i] goes to face2[i] (it gets pushed forward in the cycle)
    // Wait — _cycleEdges does: p1[i] = p4[i], p4[i] = p3[i], p3[i] = p2[i], p2[i] = old p1[i]
    // So old p1 -> p2, old p2 -> p3, old p3 -> p4, old p4 -> p1

    switch (moveFace) {
      case CubeFace.u:
        // Face rotation
        if (face == CubeFace.u) return MapEntry(face, cwFace[index]);
        // Edge cycle: F[0,1,2] -> L[0,1,2] -> B[0,1,2] -> R[0,1,2] -> F[0,1,2]
        // _cycleEdges(f,[0,1,2], l,[0,1,2], b,[0,1,2], r,[0,1,2])
        // old f->l, old l->b, old b->r, old r->f
        const uEdges = [
          [CubeFace.f, 0],
          [CubeFace.f, 1],
          [CubeFace.f, 2],
          [CubeFace.l, 0],
          [CubeFace.l, 1],
          [CubeFace.l, 2],
          [CubeFace.b, 0],
          [CubeFace.b, 1],
          [CubeFace.b, 2],
          [CubeFace.r, 0],
          [CubeFace.r, 1],
          [CubeFace.r, 2],
        ];
        const uNext = [
          [CubeFace.l, 0],
          [CubeFace.l, 1],
          [CubeFace.l, 2],
          [CubeFace.b, 0],
          [CubeFace.b, 1],
          [CubeFace.b, 2],
          [CubeFace.r, 0],
          [CubeFace.r, 1],
          [CubeFace.r, 2],
          [CubeFace.f, 0],
          [CubeFace.f, 1],
          [CubeFace.f, 2],
        ];
        for (int k = 0; k < uEdges.length; k++) {
          if (uEdges[k][0] == face && uEdges[k][1] == index) {
            return MapEntry(uNext[k][0] as CubeFace, uNext[k][1] as int);
          }
        }
        return MapEntry(face, index);

      case CubeFace.d:
        if (face == CubeFace.d) return MapEntry(face, cwFace[index]);
        // _cycleEdges(f,[6,7,8], r,[6,7,8], b,[6,7,8], l,[6,7,8])
        // old f->r, old r->b, old b->l, old l->f
        const dEdges = [
          [CubeFace.f, 6],
          [CubeFace.f, 7],
          [CubeFace.f, 8],
          [CubeFace.r, 6],
          [CubeFace.r, 7],
          [CubeFace.r, 8],
          [CubeFace.b, 6],
          [CubeFace.b, 7],
          [CubeFace.b, 8],
          [CubeFace.l, 6],
          [CubeFace.l, 7],
          [CubeFace.l, 8],
        ];
        const dNext = [
          [CubeFace.r, 6],
          [CubeFace.r, 7],
          [CubeFace.r, 8],
          [CubeFace.b, 6],
          [CubeFace.b, 7],
          [CubeFace.b, 8],
          [CubeFace.l, 6],
          [CubeFace.l, 7],
          [CubeFace.l, 8],
          [CubeFace.f, 6],
          [CubeFace.f, 7],
          [CubeFace.f, 8],
        ];
        for (int k = 0; k < dEdges.length; k++) {
          if (dEdges[k][0] == face && dEdges[k][1] == index) {
            return MapEntry(dNext[k][0] as CubeFace, dNext[k][1] as int);
          }
        }
        return MapEntry(face, index);

      case CubeFace.f:
        if (face == CubeFace.f) return MapEntry(face, cwFace[index]);
        // _cycleEdgesComplex(u,[6,7,8], r,[0,3,6], d,[2,1,0], l,[8,5,2])
        // old u->r, old r->d, old d->l, old l->u
        const fEdges = [
          [CubeFace.u, 6],
          [CubeFace.u, 7],
          [CubeFace.u, 8],
          [CubeFace.r, 0],
          [CubeFace.r, 3],
          [CubeFace.r, 6],
          [CubeFace.d, 2],
          [CubeFace.d, 1],
          [CubeFace.d, 0],
          [CubeFace.l, 8],
          [CubeFace.l, 5],
          [CubeFace.l, 2],
        ];
        const fNext = [
          [CubeFace.r, 0],
          [CubeFace.r, 3],
          [CubeFace.r, 6],
          [CubeFace.d, 2],
          [CubeFace.d, 1],
          [CubeFace.d, 0],
          [CubeFace.l, 8],
          [CubeFace.l, 5],
          [CubeFace.l, 2],
          [CubeFace.u, 6],
          [CubeFace.u, 7],
          [CubeFace.u, 8],
        ];
        for (int k = 0; k < fEdges.length; k++) {
          if (fEdges[k][0] == face && fEdges[k][1] == index) {
            return MapEntry(fNext[k][0] as CubeFace, fNext[k][1] as int);
          }
        }
        return MapEntry(face, index);

      case CubeFace.b:
        if (face == CubeFace.b) return MapEntry(face, cwFace[index]);
        // _cycleEdgesComplex(u,[2,1,0], l,[0,3,6], d,[6,7,8], r,[8,5,2])
        // old u->l, old l->d, old d->r, old r->u
        const bEdges = [
          [CubeFace.u, 2],
          [CubeFace.u, 1],
          [CubeFace.u, 0],
          [CubeFace.l, 0],
          [CubeFace.l, 3],
          [CubeFace.l, 6],
          [CubeFace.d, 6],
          [CubeFace.d, 7],
          [CubeFace.d, 8],
          [CubeFace.r, 8],
          [CubeFace.r, 5],
          [CubeFace.r, 2],
        ];
        const bNext = [
          [CubeFace.l, 0],
          [CubeFace.l, 3],
          [CubeFace.l, 6],
          [CubeFace.d, 6],
          [CubeFace.d, 7],
          [CubeFace.d, 8],
          [CubeFace.r, 8],
          [CubeFace.r, 5],
          [CubeFace.r, 2],
          [CubeFace.u, 2],
          [CubeFace.u, 1],
          [CubeFace.u, 0],
        ];
        for (int k = 0; k < bEdges.length; k++) {
          if (bEdges[k][0] == face && bEdges[k][1] == index) {
            return MapEntry(bNext[k][0] as CubeFace, bNext[k][1] as int);
          }
        }
        return MapEntry(face, index);

      case CubeFace.r:
        if (face == CubeFace.r) return MapEntry(face, cwFace[index]);
        // _cycleEdgesComplex(u,[2,5,8], b,[6,3,0], d,[2,5,8], f,[2,5,8])
        // old u->b, old b->d, old d->f, old f->u
        const rEdges = [
          [CubeFace.u, 2],
          [CubeFace.u, 5],
          [CubeFace.u, 8],
          [CubeFace.b, 6],
          [CubeFace.b, 3],
          [CubeFace.b, 0],
          [CubeFace.d, 2],
          [CubeFace.d, 5],
          [CubeFace.d, 8],
          [CubeFace.f, 2],
          [CubeFace.f, 5],
          [CubeFace.f, 8],
        ];
        const rNext = [
          [CubeFace.b, 6],
          [CubeFace.b, 3],
          [CubeFace.b, 0],
          [CubeFace.d, 2],
          [CubeFace.d, 5],
          [CubeFace.d, 8],
          [CubeFace.f, 2],
          [CubeFace.f, 5],
          [CubeFace.f, 8],
          [CubeFace.u, 2],
          [CubeFace.u, 5],
          [CubeFace.u, 8],
        ];
        for (int k = 0; k < rEdges.length; k++) {
          if (rEdges[k][0] == face && rEdges[k][1] == index) {
            return MapEntry(rNext[k][0] as CubeFace, rNext[k][1] as int);
          }
        }
        return MapEntry(face, index);

      case CubeFace.l:
        if (face == CubeFace.l) return MapEntry(face, cwFace[index]);
        // _cycleEdgesComplex(u,[0,3,6], f,[0,3,6], d,[0,3,6], b,[8,5,2])
        // old u->f, old f->d, old d->b, old b->u
        const lEdges = [
          [CubeFace.u, 0],
          [CubeFace.u, 3],
          [CubeFace.u, 6],
          [CubeFace.f, 0],
          [CubeFace.f, 3],
          [CubeFace.f, 6],
          [CubeFace.d, 0],
          [CubeFace.d, 3],
          [CubeFace.d, 6],
          [CubeFace.b, 8],
          [CubeFace.b, 5],
          [CubeFace.b, 2],
        ];
        const lNext = [
          [CubeFace.f, 0],
          [CubeFace.f, 3],
          [CubeFace.f, 6],
          [CubeFace.d, 0],
          [CubeFace.d, 3],
          [CubeFace.d, 6],
          [CubeFace.b, 8],
          [CubeFace.b, 5],
          [CubeFace.b, 2],
          [CubeFace.u, 0],
          [CubeFace.u, 3],
          [CubeFace.u, 6],
        ];
        for (int k = 0; k < lEdges.length; k++) {
          if (lEdges[k][0] == face && lEdges[k][1] == index) {
            return MapEntry(lNext[k][0] as CubeFace, lNext[k][1] as int);
          }
        }
        return MapEntry(face, index);
    }
  }

  @override
  String toString() {
    return u.join() + d.join() + f.join() + b.join() + r.join() + l.join();
  }

  /// Whole-cube rotation X (CW looking from R): F->U, U->B, B->D, D->F
  CubeState rotateX() {
    final state = clone();
    final tempU = List<CubeColor>.from(u);
    final tempF = List<CubeColor>.from(f);
    final tempD = List<CubeColor>.from(d);
    final tempB = List<CubeColor>.from(b);

    state.u.setAll(0, tempF);
    state.f.setAll(0, tempD);
    state.d.setAll(0, _rotate180Fixed(tempB));
    state.b.setAll(0, _rotate180Fixed(tempU));

    state._rotateFaceClockwise(state.r);
    state._rotateFaceCounterClockwise(state.l);
    return state;
  }

  /// Whole-cube rotation Y (CW looking from U): F->L, L->B, B->R, R->F
  CubeState rotateY() {
    final state = clone();
    final tempF = List<CubeColor>.from(f);
    final tempL = List<CubeColor>.from(l);
    final tempB = List<CubeColor>.from(b);
    final tempR = List<CubeColor>.from(r);

    state.f.setAll(0, tempR);
    state.l.setAll(0, tempF);
    state.b.setAll(0, tempL);
    state.r.setAll(0, tempB);

    state._rotateFaceClockwise(state.u);
    state._rotateFaceCounterClockwise(state.d);
    return state;
  }

  /// Whole-cube rotation Z (CW looking from F): U->R, R->D, D->L, L->U
  CubeState rotateZ() {
    final state = clone();
    final tempU = List<CubeColor>.from(u);
    final tempR = List<CubeColor>.from(r);
    final tempD = List<CubeColor>.from(d);
    final tempL = List<CubeColor>.from(l);

    state.r.setAll(0, _rotateFaceClockwiseCloned(tempU));
    state.d.setAll(0, _rotateFaceClockwiseCloned(tempR));
    state.l.setAll(0, _rotateFaceClockwiseCloned(tempD));
    state.u.setAll(0, _rotateFaceClockwiseCloned(tempL));

    state._rotateFaceClockwise(state.f);
    state._rotateFaceCounterClockwise(state.b);
    return state;
  }

  List<CubeColor> _rotateFaceClockwiseCloned(List<CubeColor> face) {
    final res = List<CubeColor>.from(face);
    _rotateFaceClockwise(res);
    return res;
  }

  List<CubeColor> _rotate180Fixed(List<CubeColor> face) {
    final res = List<CubeColor>.from(face);
    _rotateFace180(res);
    return res;
  }
}
