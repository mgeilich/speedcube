/// Represents a single move on a puzzle cube using standard notation.
enum CubeFace { u, d, r, l, f, b }

/// A move on a puzzle cube (e.g., R, R', R2)
class CubeMove {
  final CubeFace face;
  final int turns; // 1 = clockwise, -1 = counter-clockwise, 2 = 180°

  const CubeMove(this.face, [this.turns = 1]);

  // Standard moves
  static const u = CubeMove(CubeFace.u);
  static const uPrime = CubeMove(CubeFace.u, -1);
  static const u2 = CubeMove(CubeFace.u, 2);
  static const d = CubeMove(CubeFace.d);
  static const dPrime = CubeMove(CubeFace.d, -1);
  static const d2 = CubeMove(CubeFace.d, 2);
  static const r = CubeMove(CubeFace.r);
  static const rPrime = CubeMove(CubeFace.r, -1);
  static const r2 = CubeMove(CubeFace.r, 2);
  static const l = CubeMove(CubeFace.l);
  static const lPrime = CubeMove(CubeFace.l, -1);
  static const l2 = CubeMove(CubeFace.l, 2);
  static const f = CubeMove(CubeFace.f);
  static const fPrime = CubeMove(CubeFace.f, -1);
  static const f2 = CubeMove(CubeFace.f, 2);
  static const b = CubeMove(CubeFace.b);
  static const bPrime = CubeMove(CubeFace.b, -1);
  static const b2 = CubeMove(CubeFace.b, 2);

  static const allMoves = [
    u,
    uPrime,
    u2,
    d,
    dPrime,
    d2,
    r,
    rPrime,
    r2,
    l,
    lPrime,
    l2,
    f,
    fPrime,
    f2,
    b,
    bPrime,
    b2,
  ];

  static const singleMoves = [
    u,
    d,
    r,
    l,
    f,
    b,
    uPrime,
    dPrime,
    rPrime,
    lPrime,
    fPrime,
    bPrime
  ];

  /// Get the inverse of this move
  CubeMove get inverse {
    if (turns == 2) return this;
    return CubeMove(face, -turns);
  }

  /// Rotation angle in radians for animation
  double get angle {
    const quarterTurn = 3.14159265359 / 2;
    return turns * quarterTurn;
  }

  /// Parse from standard notation (e.g., "R", "R'", "R2")
  static CubeMove? parse(String notation) {
    if (notation.isEmpty) return null;

    final faceChar = notation[0].toUpperCase();
    final CubeFace? face;
    switch (faceChar) {
      case 'U':
        face = CubeFace.u;
        break;
      case 'D':
        face = CubeFace.d;
        break;
      case 'R':
        face = CubeFace.r;
        break;
      case 'L':
        face = CubeFace.l;
        break;
      case 'F':
        face = CubeFace.f;
        break;
      case 'B':
        face = CubeFace.b;
        break;
      default:
        return null;
    }

    int turns = 1;
    if (notation.length > 1) {
      if (notation.endsWith("'") || notation.endsWith("'")) {
        turns = -1;
      } else if (notation.endsWith("2")) {
        turns = 2;
      }
    }

    return CubeMove(face, turns);
  }

  @override
  String toString() {
    final faceStr = face.name.toUpperCase();
    final normalized = (turns % 4 + 4) % 4;
    if (normalized == 0) return "";
    if (normalized == 1) return faceStr;
    if (normalized == 2) return "${faceStr}2";
    return "$faceStr'";
  }

  @override
  bool operator ==(Object other) =>
      other is CubeMove && other.face == face && other.turns == turns;

  @override
  int get hashCode => face.hashCode ^ turns.hashCode;
}
