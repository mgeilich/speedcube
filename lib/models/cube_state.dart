import 'dart:math';
import 'cube_move.dart';

/// Represents the colors on the cube
enum CubeColor { white, yellow, green, blue, red, orange }

/// Represents the complete state of a puzzle cube.
class CubeState {
  // Each face has 9 stickers, indexed 0-8
  final List<CubeColor> u; // Up face
  final List<CubeColor> d; // Down face
  final List<CubeColor> f; // Front face
  final List<CubeColor> b; // Back face
  final List<CubeColor> r; // Right face
  final List<CubeColor> l; // Left face
  int? _hashCode;

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

  factory CubeState.yellowTopSolved() {
    return CubeState._(
      u: List.filled(9, CubeColor.yellow),
      d: List.filled(9, CubeColor.white),
      f: List.filled(9, CubeColor.green),
      b: List.filled(9, CubeColor.blue),
      r: List.filled(9, CubeColor.orange),
      l: List.filled(9, CubeColor.red),
    );
  }

  CubeState clone() {
    return CubeState._(
      u: List<CubeColor>.from(u),
      d: List<CubeColor>.from(d),
      f: List<CubeColor>.from(f),
      b: List<CubeColor>.from(b),
      r: List<CubeColor>.from(r),
      l: List<CubeColor>.from(l),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CubeState) return false;
    
    for (int i = 0; i < 9; i++) {
      if (u[i] != other.u[i]) return false;
      if (d[i] != other.d[i]) return false;
      if (f[i] != other.f[i]) return false;
      if (b[i] != other.b[i]) return false;
      if (r[i] != other.r[i]) return false;
      if (l[i] != other.l[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    if (_hashCode != null) return _hashCode!;
    
    int h = 0;
    for (int i = 0; i < 9; i++) {
      h = h * 31 + u[i].index;
      h = h * 31 + d[i].index;
      h = h * 31 + f[i].index;
      h = h * 31 + b[i].index;
      h = h * 31 + r[i].index;
      h = h * 31 + l[i].index;
    }
    _hashCode = h;
    return h;
  }



  bool get isSolved {
    bool faceIsSolved(List<CubeColor> face) {
      final color = face[4];
      return face.every((c) => c == color);
    }
    return faceIsSolved(u) && faceIsSolved(d) && faceIsSolved(f) && faceIsSolved(b) && faceIsSolved(r) && faceIsSolved(l);
  }

  List<CubeColor> get allStickers => [...u, ...d, ...f, ...b, ...r, ...l];

  CubeState applyMove(CubeMove move) {
    if (move.face == CubeFace.x) {
      if (move.turns == 1) return rotateX();
      if (move.turns == -1) return rotateX().rotateX().rotateX();
      if (move.turns == 2) return rotateX().rotateX();
    }
    if (move.face == CubeFace.y) {
      if (move.turns == 1) return rotateY();
      if (move.turns == -1) return rotateY().rotateY().rotateY();
      if (move.turns == 2) return rotateY().rotateY();
    }
    if (move.face == CubeFace.z) {
      if (move.turns == 1) return rotateZ();
      if (move.turns == -1) return rotateZ().rotateZ().rotateZ();
      if (move.turns == 2) return rotateZ().rotateZ();
    }

    if (move.isWide) {
      // Decompose wide move into face move + inverse slice move
      // Rw = R + M', Lw = L + M, etc.
      List<CubeMove> componentMoves = [];
      componentMoves.add(CubeMove(move.face, move.turns, false));
      switch (move.face) {
        case CubeFace.r: componentMoves.add(CubeMove(CubeFace.m, -move.turns)); break;
        case CubeFace.l: componentMoves.add(CubeMove(CubeFace.m, move.turns)); break;
        case CubeFace.u: componentMoves.add(CubeMove(CubeFace.e, -move.turns)); break;
        case CubeFace.d: componentMoves.add(CubeMove(CubeFace.e, move.turns)); break;
        case CubeFace.f: componentMoves.add(CubeMove(CubeFace.s, move.turns)); break;
        case CubeFace.b: componentMoves.add(CubeMove(CubeFace.s, -move.turns)); break;
        default: break;
      }
      return applyMoves(componentMoves);
    }

    final state = clone();
    int turns = move.turns;
    if (turns == -1) turns = 3;
    if (turns == 2) turns = 2;

    for (int i = 0; i < turns; i++) {
      state._applyQuarterTurn(move.face);
    }
    return state;
  }

  CubeState applyMoves(List<CubeMove> moves) {
    CubeState state = this;
    for (final move in moves) {
      state = state.applyMove(move);
    }
    return state;
  }

  static List<CubeMove> generateScramble([int length = 20]) {
    final random = Random();
    final moves = <CubeMove>[];
    CubeFace? lastFace;
    while (moves.length < length) {
      final move = CubeMove.physicalSingleMoves[random.nextInt(CubeMove.physicalSingleMoves.length)];
      if (move.face != lastFace) {
        moves.add(move);
        lastFace = move.face;
      }
    }
    return moves;
  }

  void _applyQuarterTurn(CubeFace face) {
    switch (face) {
      case CubeFace.u:
        _rotateFaceClockwise(u);
        _cycleEdges(f, [0, 1, 2], l, [0, 1, 2], b, [0, 1, 2], r, [0, 1, 2]);
        break;
      case CubeFace.d:
        _rotateFaceClockwise(d);
        _cycleEdges(f, [6, 7, 8], r, [6, 7, 8], b, [6, 7, 8], l, [6, 7, 8]);
        break;
      case CubeFace.f:
        _rotateFaceClockwise(f);
        _cycleEdgesComplex(u, [6, 7, 8], r, [0, 3, 6], d, [2, 1, 0], l, [8, 5, 2]);
        break;
      case CubeFace.b:
        _rotateFaceClockwise(b);
        _cycleEdgesComplex(u, [2, 1, 0], l, [0, 3, 6], d, [6, 7, 8], r, [8, 5, 2]);
        break;
      case CubeFace.r:
        _rotateFaceClockwise(r);
        _cycleEdgesComplex(u, [2, 5, 8], b, [6, 3, 0], d, [2, 5, 8], f, [2, 5, 8]);
        break;
      case CubeFace.l:
        _rotateFaceClockwise(l);
        _cycleEdgesComplex(u, [0, 3, 6], f, [0, 3, 6], d, [0, 3, 6], b, [8, 5, 2]);
        break;
      case CubeFace.m:
        // M is in direction of L: U -> F -> D -> B -> U
        _cycleEdgesComplex(u, [1, 4, 7], f, [1, 4, 7], d, [1, 4, 7], b, [7, 4, 1]);
        break;
      case CubeFace.e:
        // E is in direction of D: F -> R -> B -> L -> F
        _cycleEdgesComplex(f, [3, 4, 5], r, [3, 4, 5], b, [3, 4, 5], l, [3, 4, 5]);
        break;
      case CubeFace.s:
        // S is in direction of F: U -> R -> D -> L -> U
        _cycleEdgesComplex(u, [3, 4, 5], r, [1, 4, 7], d, [5, 4, 3], l, [7, 4, 1]);
        break;
      default:
        break;
    }
  }

  void _rotateFaceClockwise(List<CubeColor> face) {
    final temp = List<CubeColor>.from(face);
    face[0] = temp[6]; face[1] = temp[3]; face[2] = temp[0];
    face[3] = temp[7]; face[4] = temp[4]; face[5] = temp[1];
    face[6] = temp[8]; face[7] = temp[5]; face[8] = temp[2];
  }

  void _rotateFaceCounterClockwise(List<CubeColor> face) {
    final temp = List<CubeColor>.from(face);
    face[0] = temp[2]; face[1] = temp[5]; face[2] = temp[8];
    face[3] = temp[1]; face[4] = temp[4]; face[5] = temp[7];
    face[6] = temp[0]; face[7] = temp[3]; face[8] = temp[6];
  }

  void _rotateFace180(List<CubeColor> face) {
    final temp = List<CubeColor>.from(face);
    face[0] = temp[8]; face[1] = temp[7]; face[2] = temp[6];
    face[3] = temp[5]; face[4] = temp[4]; face[5] = temp[3];
    face[6] = temp[2]; face[7] = temp[1]; face[8] = temp[0];
  }

  void _cycleEdges(List<CubeColor> p1, List<int> i1, List<CubeColor> p2, List<int> i2, List<CubeColor> p3, List<int> i3, List<CubeColor> p4, List<int> i4) {
    for (int i = 0; i < 3; i++) {
        final temp = p1[i1[i]];
        p1[i1[i]] = p4[i4[i]];
        p4[i4[i]] = p3[i3[i]];
        p3[i3[i]] = p2[i2[i]];
        p2[i2[i]] = temp;
    }
  }

  void _cycleEdgesComplex(List<CubeColor> p1, List<int> i1, List<CubeColor> p2, List<int> i2, List<CubeColor> p3, List<int> i3, List<CubeColor> p4, List<int> i4) {
    _cycleEdges(p1, i1, p2, i2, p3, i3, p4, i4);
  }

  List<CubeColor> getFace(CubeFace face) {
    switch (face) {
      case CubeFace.u: return u;
      case CubeFace.d: return d;
      case CubeFace.f: return f;
      case CubeFace.b: return b;
      case CubeFace.r: return r;
      case CubeFace.l: return l;
      default: return [];
    }
  }

  MapEntry<CubeFace, int> stickerAfterMove(CubeFace face, int index, CubeMove move) {
    if (move.isWide) {
      // Decompose wide move logic
      var current = MapEntry(face, index);
      // Face move
      current = stickerAfterMove(current.key, current.value, CubeMove(move.face, move.turns));
      // Slice move
      switch (move.face) {
        case CubeFace.r: return stickerAfterMove(current.key, current.value, CubeMove(CubeFace.m, -move.turns));
        case CubeFace.l: return stickerAfterMove(current.key, current.value, CubeMove(CubeFace.m, move.turns));
        case CubeFace.u: return stickerAfterMove(current.key, current.value, CubeMove(CubeFace.e, -move.turns));
        case CubeFace.d: return stickerAfterMove(current.key, current.value, CubeMove(CubeFace.e, move.turns));
        case CubeFace.f: return stickerAfterMove(current.key, current.value, CubeMove(CubeFace.s, move.turns));
        case CubeFace.b: return stickerAfterMove(current.key, current.value, CubeMove(CubeFace.s, -move.turns));
        default: return current;
      }
    }

    int turns = move.turns;
    if (turns == -1) turns = 3;
    if (turns == 2) turns = 2;
    var result = MapEntry(face, index);
    for (int i = 0; i < turns; i++) {
      result = _stickerAfterQuarterTurn(result.key, result.value, move.face);
    }
    return result;
  }

  MapEntry<CubeFace, int> _stickerAfterQuarterTurn(CubeFace face, int index, CubeFace moveFace) {
    const cwFace = [2, 5, 8, 1, 4, 7, 0, 3, 6];
    switch (moveFace) {
      case CubeFace.u:
        if (face == CubeFace.u) return MapEntry(face, cwFace[index]);
        const uE = [[CubeFace.f, 0], [CubeFace.f, 1], [CubeFace.f, 2], [CubeFace.l, 0], [CubeFace.l, 1], [CubeFace.l, 2], [CubeFace.b, 0], [CubeFace.b, 1], [CubeFace.b, 2], [CubeFace.r, 0], [CubeFace.r, 1], [CubeFace.r, 2]];
        const uN = [[CubeFace.l, 0], [CubeFace.l, 1], [CubeFace.l, 2], [CubeFace.b, 0], [CubeFace.b, 1], [CubeFace.b, 2], [CubeFace.r, 0], [CubeFace.r, 1], [CubeFace.r, 2], [CubeFace.f, 0], [CubeFace.f, 1], [CubeFace.f, 2]];
        for (int k = 0; k < uE.length; k++) {
          if (uE[k][0] == face && uE[k][1] == index) {
            return MapEntry(uN[k][0] as CubeFace, uN[k][1] as int);
          }
        }
        return MapEntry(face, index);
      case CubeFace.d:
        if (face == CubeFace.d) return MapEntry(face, cwFace[index]);
        const dE = [[CubeFace.f, 6], [CubeFace.f, 7], [CubeFace.f, 8], [CubeFace.r, 6], [CubeFace.r, 7], [CubeFace.r, 8], [CubeFace.b, 6], [CubeFace.b, 7], [CubeFace.b, 8], [CubeFace.l, 6], [CubeFace.l, 7], [CubeFace.l, 8]];
        const dN = [[CubeFace.r, 6], [CubeFace.r, 7], [CubeFace.r, 8], [CubeFace.b, 6], [CubeFace.b, 7], [CubeFace.b, 8], [CubeFace.l, 6], [CubeFace.l, 7], [CubeFace.l, 8], [CubeFace.f, 6], [CubeFace.f, 7], [CubeFace.f, 8]];
        for (int k = 0; k < dE.length; k++) {
          if (dE[k][0] == face && dE[k][1] == index) {
            return MapEntry(dN[k][0] as CubeFace, dN[k][1] as int);
          }
        }
        return MapEntry(face, index);
      case CubeFace.f:
        if (face == CubeFace.f) return MapEntry(face, cwFace[index]);
        const fE = [[CubeFace.u, 6], [CubeFace.u, 7], [CubeFace.u, 8], [CubeFace.r, 0], [CubeFace.r, 3], [CubeFace.r, 6], [CubeFace.d, 2], [CubeFace.d, 1], [CubeFace.d, 0], [CubeFace.l, 8], [CubeFace.l, 5], [CubeFace.l, 2]];
        const fN = [[CubeFace.r, 0], [CubeFace.r, 3], [CubeFace.r, 6], [CubeFace.d, 2], [CubeFace.d, 1], [CubeFace.d, 0], [CubeFace.l, 8], [CubeFace.l, 5], [CubeFace.l, 2], [CubeFace.u, 6], [CubeFace.u, 7], [CubeFace.u, 8]];
        for (int k = 0; k < fE.length; k++) {
          if (fE[k][0] == face && fE[k][1] == index) {
            return MapEntry(fN[k][0] as CubeFace, fN[k][1] as int);
          }
        }
        return MapEntry(face, index);
      case CubeFace.b:
        if (face == CubeFace.b) return MapEntry(face, cwFace[index]);
        const bE = [[CubeFace.u, 2], [CubeFace.u, 1], [CubeFace.u, 0], [CubeFace.l, 0], [CubeFace.l, 3], [CubeFace.l, 6], [CubeFace.d, 6], [CubeFace.d, 7], [CubeFace.d, 8], [CubeFace.r, 8], [CubeFace.r, 5], [CubeFace.r, 2]];
        const bN = [[CubeFace.l, 0], [CubeFace.l, 3], [CubeFace.l, 6], [CubeFace.d, 6], [CubeFace.d, 7], [CubeFace.d, 8], [CubeFace.r, 8], [CubeFace.r, 5], [CubeFace.r, 2], [CubeFace.u, 2], [CubeFace.u, 1], [CubeFace.u, 0]];
        for (int k = 0; k < bE.length; k++) {
          if (bE[k][0] == face && bE[k][1] == index) {
            return MapEntry(bN[k][0] as CubeFace, bN[k][1] as int);
          }
        }
        return MapEntry(face, index);
      case CubeFace.r:
        if (face == CubeFace.r) return MapEntry(face, cwFace[index]);
        const rE = [[CubeFace.u, 2], [CubeFace.u, 5], [CubeFace.u, 8], [CubeFace.b, 6], [CubeFace.b, 3], [CubeFace.b, 0], [CubeFace.d, 2], [CubeFace.d, 5], [CubeFace.d, 8], [CubeFace.f, 2], [CubeFace.f, 5], [CubeFace.f, 8]];
        const rN = [[CubeFace.b, 6], [CubeFace.b, 3], [CubeFace.b, 0], [CubeFace.d, 2], [CubeFace.d, 5], [CubeFace.d, 8], [CubeFace.f, 2], [CubeFace.f, 5], [CubeFace.f, 8], [CubeFace.u, 2], [CubeFace.u, 5], [CubeFace.u, 8]];
        for (int k = 0; k < rE.length; k++) {
          if (rE[k][0] == face && rE[k][1] == index) {
            return MapEntry(rN[k][0] as CubeFace, rN[k][1] as int);
          }
        }
        return MapEntry(face, index);
      case CubeFace.l:
        if (face == CubeFace.l) return MapEntry(face, cwFace[index]);
        const lE = [[CubeFace.u, 0], [CubeFace.u, 3], [CubeFace.u, 6], [CubeFace.f, 0], [CubeFace.f, 3], [CubeFace.f, 6], [CubeFace.d, 0], [CubeFace.d, 3], [CubeFace.d, 6], [CubeFace.b, 8], [CubeFace.b, 5], [CubeFace.b, 2]];
        const lN = [[CubeFace.f, 0], [CubeFace.f, 3], [CubeFace.f, 6], [CubeFace.d, 0], [CubeFace.d, 3], [CubeFace.d, 6], [CubeFace.b, 8], [CubeFace.b, 5], [CubeFace.b, 2], [CubeFace.u, 0], [CubeFace.u, 3], [CubeFace.u, 6]];
        for (int k = 0; k < lE.length; k++) {
          if (lE[k][0] == face && lE[k][1] == index) {
            return MapEntry(lN[k][0] as CubeFace, lN[k][1] as int);
          }
        }
        return MapEntry(face, index);
      case CubeFace.m:
        const mE = [[CubeFace.u, 1], [CubeFace.u, 4], [CubeFace.u, 7], [CubeFace.f, 1], [CubeFace.f, 4], [CubeFace.f, 7], [CubeFace.d, 1], [CubeFace.d, 4], [CubeFace.d, 7], [CubeFace.b, 7], [CubeFace.b, 4], [CubeFace.b, 1]];
        const mN = [[CubeFace.f, 1], [CubeFace.f, 4], [CubeFace.f, 7], [CubeFace.d, 1], [CubeFace.d, 4], [CubeFace.d, 7], [CubeFace.b, 7], [CubeFace.b, 4], [CubeFace.b, 1], [CubeFace.u, 1], [CubeFace.u, 4], [CubeFace.u, 7]];
        for (int k = 0; k < mE.length; k++) {
          if (mE[k][0] == face && mE[k][1] == index) {
            return MapEntry(mN[k][0] as CubeFace, mN[k][1] as int);
          }
        }
        return MapEntry(face, index);
      case CubeFace.e:
        const eE = [[CubeFace.f, 3], [CubeFace.f, 4], [CubeFace.f, 5], [CubeFace.r, 3], [CubeFace.r, 4], [CubeFace.r, 5], [CubeFace.b, 3], [CubeFace.b, 4], [CubeFace.b, 5], [CubeFace.l, 3], [CubeFace.l, 4], [CubeFace.l, 5]];
        const eN = [[CubeFace.r, 3], [CubeFace.r, 4], [CubeFace.r, 5], [CubeFace.b, 3], [CubeFace.b, 4], [CubeFace.b, 5], [CubeFace.l, 3], [CubeFace.l, 4], [CubeFace.l, 5], [CubeFace.f, 3], [CubeFace.f, 4], [CubeFace.f, 5]];
        for (int k = 0; k < eE.length; k++) {
          if (eE[k][0] == face && eE[k][1] == index) {
            return MapEntry(eN[k][0] as CubeFace, eN[k][1] as int);
          }
        }
        return MapEntry(face, index);
      case CubeFace.s:
        const sE = [[CubeFace.u, 3], [CubeFace.u, 4], [CubeFace.u, 5], [CubeFace.r, 1], [CubeFace.r, 4], [CubeFace.r, 7], [CubeFace.d, 5], [CubeFace.d, 4], [CubeFace.d, 3], [CubeFace.l, 7], [CubeFace.l, 4], [CubeFace.l, 1]];
        const sN = [[CubeFace.r, 1], [CubeFace.r, 4], [CubeFace.r, 7], [CubeFace.d, 5], [CubeFace.d, 4], [CubeFace.d, 3], [CubeFace.l, 7], [CubeFace.l, 4], [CubeFace.l, 1], [CubeFace.u, 3], [CubeFace.u, 4], [CubeFace.u, 5]];
        for (int k = 0; k < sE.length; k++) {
          if (sE[k][0] == face && sE[k][1] == index) {
            return MapEntry(sN[k][0] as CubeFace, sN[k][1] as int);
          }
        }
        return MapEntry(face, index);
      default:
        return MapEntry(face, index);
    }
  }

  CubeState rotateX() {
    final state = clone();
    final tempU = List<CubeColor>.from(u);
    state.u.setAll(0, f);
    state.f.setAll(0, d);
    state.d.setAll(0, _rotate180Fixed(b));
    state.b.setAll(0, _rotate180Fixed(tempU));
    state._rotateFaceClockwise(state.r);
    state._rotateFaceCounterClockwise(state.l);
    return state;
  }

  CubeState rotateY() {
    final state = clone();
    final tempF = List<CubeColor>.from(f);
    state.f.setAll(0, r);
    state.r.setAll(0, b);
    state.b.setAll(0, l);
    state.l.setAll(0, tempF);
    state._rotateFaceClockwise(state.u);
    state._rotateFaceCounterClockwise(state.d);
    return state;
  }

  CubeState rotateZ() {
    final state = clone();
    final tempU = List<CubeColor>.from(u);
    state.u.setAll(0, _rotateFaceClockwiseCloned(l));
    state.l.setAll(0, _rotateFaceClockwiseCloned(d));
    state.d.setAll(0, _rotateFaceClockwiseCloned(r));
    state.r.setAll(0, _rotateFaceClockwiseCloned(tempU));
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
