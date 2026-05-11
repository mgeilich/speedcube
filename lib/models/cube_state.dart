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
      r: List.filled(9, CubeColor.red),
      l: List.filled(9, CubeColor.orange),
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
      List<CubeMove> componentMoves = [];
      switch (move.face) {
        case CubeFace.r:
          componentMoves.add(CubeMove(CubeFace.r, move.turns, false));
          componentMoves.add(CubeMove(CubeFace.m, -move.turns));
          break;
        case CubeFace.l:
          componentMoves.add(CubeMove(CubeFace.l, move.turns, false));
          componentMoves.add(CubeMove(CubeFace.m, move.turns));
          break;
        case CubeFace.u:
          componentMoves.add(CubeMove(CubeFace.u, move.turns, false));
          componentMoves.add(CubeMove(CubeFace.e, -move.turns));
          break;
        case CubeFace.d:
          componentMoves.add(CubeMove(CubeFace.d, move.turns, false));
          componentMoves.add(CubeMove(CubeFace.e, move.turns));
          break;
        case CubeFace.f:
          componentMoves.add(CubeMove(CubeFace.f, move.turns, false));
          componentMoves.add(CubeMove(CubeFace.s, move.turns));
          break;
        case CubeFace.b:
          componentMoves.add(CubeMove(CubeFace.b, move.turns, false));
          componentMoves.add(CubeMove(CubeFace.s, -move.turns));
          break;
        default: break;
      }
      return applyMoves(componentMoves);
    }

    final state = clone();
    int turns = (move.turns % 4 + 4) % 4;
    
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
    final s = _getAllStickers();
    
    switch (face) {
      case CubeFace.u:
        _cycle(s, [0, 2, 8, 6]); _cycle(s, [1, 5, 7, 3]);
        _cycle(s, [18, 36, 45, 9]); _cycle(s, [19, 37, 46, 10]); _cycle(s, [20, 38, 47, 11]);
        break;
      case CubeFace.d:
        _cycle(s, [27, 29, 35, 33]); _cycle(s, [28, 32, 34, 30]);
        _cycle(s, [24, 15, 51, 42]); _cycle(s, [25, 16, 52, 43]); _cycle(s, [26, 17, 53, 44]);
        break;
      case CubeFace.r:
        _cycle(s, [9, 11, 17, 15]); _cycle(s, [10, 14, 16, 12]);
        _cycle(s, [2, 51, 29, 20]); _cycle(s, [5, 48, 32, 23]); _cycle(s, [8, 45, 35, 26]);
        break;
      case CubeFace.l:
        _cycle(s, [36, 38, 44, 42]); _cycle(s, [37, 41, 43, 39]);
        _cycle(s, [0, 18, 27, 53]); _cycle(s, [3, 21, 30, 50]); _cycle(s, [6, 24, 33, 47]);
        break;
      case CubeFace.f:
        _cycle(s, [18, 20, 26, 24]); _cycle(s, [19, 23, 25, 21]);
        _cycle(s, [6, 9, 29, 44]); _cycle(s, [7, 12, 28, 41]); _cycle(s, [8, 15, 27, 38]);
        break;
      case CubeFace.b:
        _cycle(s, [45, 47, 53, 51]); _cycle(s, [46, 50, 52, 48]);
        _cycle(s, [2, 36, 33, 17]); _cycle(s, [1, 39, 34, 14]); _cycle(s, [0, 42, 35, 11]);
        break;
      case CubeFace.m:
        _cycle(s, [1, 19, 28, 52]); _cycle(s, [4, 22, 31, 49]); _cycle(s, [7, 25, 34, 46]);
        break;
      case CubeFace.e:
        _cycle(s, [21, 12, 48, 39]); _cycle(s, [22, 13, 49, 40]); _cycle(s, [23, 14, 50, 41]);
        break;
      case CubeFace.s:
        _cycle(s, [3, 10, 32, 43]); _cycle(s, [4, 13, 31, 40]); _cycle(s, [5, 16, 30, 37]);
        break;
      default: break;
    }
    _setAllStickers(s);
  }

  void _cycle(List<CubeColor> s, List<int> indices) {
    final temp = s[indices.last];
    for (int i = indices.length - 1; i > 0; i--) {
      s[indices[i]] = s[indices[i - 1]];
    }
    s[indices[0]] = temp;
  }

  List<CubeColor> _getAllStickers() => [...u, ...r, ...f, ...d, ...l, ...b];

  void _setAllStickers(List<CubeColor> s) {
    u.setAll(0, s.sublist(0, 9));
    r.setAll(0, s.sublist(9, 18));
    f.setAll(0, s.sublist(18, 27));
    d.setAll(0, s.sublist(27, 36));
    l.setAll(0, s.sublist(36, 45));
    b.setAll(0, s.sublist(45, 54));
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
    return applyMove(CubeMove(CubeFace.r, 1)).applyMove(CubeMove(CubeFace.l, -1)).applyMove(CubeMove(CubeFace.m, -1));
  }

  CubeState rotateY() {
    return applyMove(CubeMove(CubeFace.u, 1)).applyMove(CubeMove(CubeFace.d, -1)).applyMove(CubeMove(CubeFace.e, -1));
  }

  CubeState rotateZ() {
    return applyMove(CubeMove(CubeFace.f, 1)).applyMove(CubeMove(CubeFace.b, -1)).applyMove(CubeMove(CubeFace.s, 1));
  }

}
