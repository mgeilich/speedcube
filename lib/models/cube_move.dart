/// Represents a single move on a puzzle cube using standard notation.
enum CubeFace {
  u, d, r, l, f, b, x, y, z, m, e, s;
  static const physicalFaces = [u, d, r, l, f, b];
  static const sliceFaces = [m, e, s];
}

/// A move on a puzzle cube (e.g., R, R', R2, X, Y, Z)
class CubeMove {
  final CubeFace face;
  final int turns; // 1 = clockwise, -1 = counter-clockwise, 2 = 180°
  final bool isWide; // e.g., Rw, Lw

  const CubeMove(this.face, [this.turns = 1, this.isWide = false]);

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

  // Whole-cube rotations
  static const x = CubeMove(CubeFace.x);
  static const xPrime = CubeMove(CubeFace.x, -1);
  static const x2 = CubeMove(CubeFace.x, 2);
  static const y = CubeMove(CubeFace.y);
  static const yPrime = CubeMove(CubeFace.y, -1);
  static const y2 = CubeMove(CubeFace.y, 2);
  static const z = CubeMove(CubeFace.z);
  static const zPrime = CubeMove(CubeFace.z, -1);
  static const z2 = CubeMove(CubeFace.z, 2);

  // Slice moves
  static const m = CubeMove(CubeFace.m);
  static const mPrime = CubeMove(CubeFace.m, -1);
  static const m2 = CubeMove(CubeFace.m, 2);
  static const e = CubeMove(CubeFace.e);
  static const ePrime = CubeMove(CubeFace.e, -1);
  static const e2 = CubeMove(CubeFace.e, 2);
  static const sFace = CubeMove(CubeFace.s); // 's' is already in use by something? No, but let's be safe
  static const sPrime = CubeMove(CubeFace.s, -1);
  static const s2 = CubeMove(CubeFace.s, 2);

  static const physicalMoves = [
    u, uPrime, u2,
    d, dPrime, d2,
    r, rPrime, r2,
    l, lPrime, l2,
    f, fPrime, f2,
    b, bPrime, b2,
  ];

  static const sliceMoves = [
    m, mPrime, m2,
    e, ePrime, e2,
    sFace, sPrime, s2,
  ];

  static const allMoves = [
    ...physicalMoves,
    ...sliceMoves,
    x, xPrime, x2,
    y, yPrime, y2,
    z, zPrime, z2,
  ];

  static const physicalSingleMoves = [
    u, d, r, l, f, b,
    uPrime, dPrime, rPrime, lPrime, fPrime, bPrime
  ];

  static const allSingleMoves = [
    ...physicalSingleMoves,
    x, y, z,
    xPrime, yPrime, zPrime
  ];

  @Deprecated('Use physicalSingleMoves or allSingleMoves')
  static const singleMoves = physicalSingleMoves;

  /// Get the inverse of this move
  CubeMove get inverse {
    if (turns == 2) return this;
    return CubeMove(face, -turns, isWide);
  }

  /// Rotation angle in radians for animation
  double get angle {
    const quarterTurn = 3.14159265359 / 2;
    return turns * quarterTurn;
  }

  /// Parse from standard notation (e.g., "R", "X", "Y'", "Z2", "M", "Rw")
  static CubeMove? parse(String notation) {
    if (notation.isEmpty) return null;

    String cleanNotation = notation.trim();
    if (cleanNotation.isEmpty) return null;

    final faceChar = cleanNotation[0].toUpperCase();
    CubeFace? face;
    bool wide = false;

    // Check for wide moves like "Rw" or "r"
    if (cleanNotation[0] == cleanNotation[0].toLowerCase() && 
        "udrlfb".contains(cleanNotation[0])) {
      wide = true;
    }

    switch (faceChar) {
      case 'U': face = CubeFace.u; break;
      case 'D': face = CubeFace.d; break;
      case 'R': face = CubeFace.r; break;
      case 'L': face = CubeFace.l; break;
      case 'F': face = CubeFace.f; break;
      case 'B': face = CubeFace.b; break;
      case 'X': face = CubeFace.x; break;
      case 'Y': face = CubeFace.y; break;
      case 'Z': face = CubeFace.z; break;
      case 'M': face = CubeFace.m; break;
      case 'E': face = CubeFace.e; break;
      case 'S': face = CubeFace.s; break;
      default: return null;
    }

    int startIdx = 1;
    if (cleanNotation.length > startIdx && 
        (cleanNotation[startIdx] == 'w' || cleanNotation[startIdx] == 'W')) {
      wide = true;
      startIdx++;
    }

    int turns = 1;
    String suffix = cleanNotation.substring(startIdx);
    if (suffix.contains("'") || suffix.contains("’")) {
      turns = -1;
    } else if (suffix.contains("2")) {
      turns = 2;
    }

    return CubeMove(face, turns, wide);
  }

  @override
  String toString() {
    String faceStr = face.name.toUpperCase();
    if (isWide) {
      faceStr += "w";
    }
    final normalized = (turns % 4 + 4) % 4;
    if (normalized == 0) return "";
    if (normalized == 1) return faceStr;
    if (normalized == 2) return "${faceStr}2";
    return "$faceStr'";
  }

  @override
  bool operator ==(Object other) =>
      other is CubeMove && other.face == face && other.turns == turns && other.isWide == isWide;

  @override
  int get hashCode => face.hashCode ^ turns.hashCode ^ isWide.hashCode;
}
