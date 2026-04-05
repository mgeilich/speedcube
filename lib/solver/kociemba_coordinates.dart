import '../models/cube_state.dart';
import '../models/cube_move.dart';

enum Corner { uRF, uFL, uLB, uBR, dFR, dLF, dBL, dRB }

enum Edge { uR, uF, uL, uB, dR, dF, dL, dB, fR, fL, bL, bR }

class KociembaCube {
  final List<int> cp = List.generate(8, (i) => i);
  final List<int> co = List.filled(8, 0);
  final List<int> ep = List.generate(12, (i) => i);
  final List<int> eo = List.filled(12, 0);

  final Map<CubeFace, CubeColor> centers;

  KociembaCube([Map<CubeFace, CubeColor>? centers])
      : centers = centers ??
            {
              CubeFace.u: CubeColor.white,
              CubeFace.d: CubeColor.yellow,
              CubeFace.f: CubeColor.green,
              CubeFace.b: CubeColor.blue,
              CubeFace.r: CubeColor.red,
              CubeFace.l: CubeColor.orange,
            };

  String toCompactString() {
    return '${cp.join(',')}|${co.join(',')}|${ep.join(',')}|${eo.join(',')}';
  }

  bool get isSolved {
    for (int i = 0; i < 8; i++) {
      if (cp[i] != i || co[i] != 0) {
        return false;
      }
    }
    for (int i = 0; i < 12; i++) {
      if (ep[i] != i || eo[i] != 0) {
        return false;
      }
    }
    return true;
  }

  /// Number of misoriented edges (Phase 1 goal: reduce to 0)
  int get badEdgeCount => eo.where((o) => o != 0).length;

  /// Number of middle-layer edges (8, 9, 10, 11) in the middle layer slots (8, 9, 10, 11).
  /// (Phase 1 goal: get all 4 into the slice)
  int get sliceCorrectCount {
    int count = 0;
    for (int i = 8; i < 12; i++) {
      if (ep[i] >= 8) count++;
    }
    return count;
  }

  KociembaCube.clone(KociembaCube other) : centers = Map.from(other.centers) {
    for (int i = 0; i < 8; i++) {
      cp[i] = other.cp[i];
      co[i] = other.co[i];
    }
    for (int i = 0; i < 12; i++) {
      ep[i] = other.ep[i];
      eo[i] = other.eo[i];
    }
  }

  static const List<CubeFace> allFaces = [
    CubeFace.u,
    CubeFace.d,
    CubeFace.l,
    CubeFace.r,
    CubeFace.f,
    CubeFace.b
  ];

  // --- Standardized Piece Colors and Handedness ---

  Map<Corner, List<CubeColor>> get cornerColors => {
        Corner.uRF: [
          centers[CubeFace.u]!,
          centers[CubeFace.r]!,
          centers[CubeFace.f]!
        ],
        Corner.uFL: [
          centers[CubeFace.u]!,
          centers[CubeFace.f]!,
          centers[CubeFace.l]!
        ],
        Corner.uLB: [
          centers[CubeFace.u]!,
          centers[CubeFace.l]!,
          centers[CubeFace.b]!
        ],
        Corner.uBR: [
          centers[CubeFace.u]!,
          centers[CubeFace.b]!,
          centers[CubeFace.r]!
        ],
        Corner.dFR: [
          centers[CubeFace.d]!,
          centers[CubeFace.f]!,
          centers[CubeFace.r]!
        ],
        Corner.dLF: [
          centers[CubeFace.d]!,
          centers[CubeFace.l]!,
          centers[CubeFace.f]!
        ],
        Corner.dBL: [
          centers[CubeFace.d]!,
          centers[CubeFace.b]!,
          centers[CubeFace.l]!
        ],
        Corner.dRB: [
          centers[CubeFace.d]!,
          centers[CubeFace.r]!,
          centers[CubeFace.b]!
        ],
      };

  Map<Edge, List<CubeColor>> get edgeColors => {
        Edge.uR: [centers[CubeFace.u]!, centers[CubeFace.r]!],
        Edge.uF: [centers[CubeFace.u]!, centers[CubeFace.f]!],
        Edge.uL: [centers[CubeFace.u]!, centers[CubeFace.l]!],
        Edge.uB: [centers[CubeFace.u]!, centers[CubeFace.b]!],
        Edge.dR: [centers[CubeFace.d]!, centers[CubeFace.r]!],
        Edge.dF: [centers[CubeFace.d]!, centers[CubeFace.f]!],
        Edge.dL: [centers[CubeFace.d]!, centers[CubeFace.l]!],
        Edge.dB: [centers[CubeFace.d]!, centers[CubeFace.b]!],
        Edge.fR: [centers[CubeFace.f]!, centers[CubeFace.r]!],
        Edge.fL: [centers[CubeFace.f]!, centers[CubeFace.l]!],
        Edge.bL: [centers[CubeFace.b]!, centers[CubeFace.l]!],
        Edge.bR: [centers[CubeFace.b]!, centers[CubeFace.r]!],
      };

  // --- Hand-calibrated Sticker Spots (Must match CubeState) ---

  static List<int> getCornerStickers(Corner spot) {
    switch (spot) {
      case Corner.uRF:
        return [8, 36, 20]; // U8, R0, F2
      case Corner.uFL:
        return [6, 18, 47]; // U6, F0, L2
      case Corner.uLB:
        return [0, 45, 29]; // U0, L0, B2
      case Corner.uBR:
        return [2, 27, 38]; // U2, B0, R2
      case Corner.dFR:
        return [11, 26, 42]; // D2, F8, R6
      case Corner.dLF:
        return [9, 53, 24]; // D0, L8, F6
      case Corner.dBL:
        return [15, 35, 51]; // D6, B8, L6
      case Corner.dRB:
        return [17, 44, 33]; // D8, R8, B6
    }
  }

  static List<int> getEdgeStickers(Edge spot) {
    switch (spot) {
      case Edge.uR:
        return [5, 37]; // U5, R1
      case Edge.uF:
        return [7, 19]; // U7, F1
      case Edge.uL:
        return [3, 46]; // U3, L1
      case Edge.uB:
        return [1, 28]; // U1, B1
      case Edge.dR:
        return [14, 43]; // D5, R7
      case Edge.dF:
        return [10, 25]; // D1, F7
      case Edge.dL:
        return [12, 52]; // D3, L7
      case Edge.dB:
        return [16, 34]; // D7, B7
      case Edge.fR:
        return [23, 39]; // F5, R3
      case Edge.fL:
        return [21, 50]; // F3, L5
      case Edge.bL:
        return [32, 48]; // B5, L3
      case Edge.bR:
        return [30, 41]; // B3, R5
    }
  }

  Map<int, int> _buildCornerLookup() {
    final res = <int, int>{};
    final colors = cornerColors;
    for (int i = 0; i < 8; i++) {
      int mask = 0;
      for (final c in colors[Corner.values[i]]!) {
        mask |= (1 << c.index);
      }
      res[mask] = i;
    }
    return res;
  }

  Map<int, int> _buildEdgeLookup() {
    final res = <int, int>{};
    final colors = edgeColors;
    for (int i = 0; i < 12; i++) {
      int mask = 0;
      for (final c in colors[Edge.values[i]]!) {
        mask |= (1 << c.index);
      }
      res[mask] = i;
    }
    return res;
  }

  // --- Move logic (Physical-backed for absolute correctness) ---

  void applyMove(CubeFace face, int turns) {
    int count = (turns % 4 + 4) % 4;
    for (int i = 0; i < count; i++) {
      _applySingleMove(face);
    }
  }

  void _applySingleMove(CubeFace face) {
    switch (face) {
      case CubeFace.u:
        _cycle4(cp, [0, 1, 2, 3], co, [0, 0, 0, 0], 3);
        _cycle4(ep, [0, 1, 2, 3], eo, [0, 0, 0, 0], 2);
        break;
      case CubeFace.d:
        _cycle4(cp, [4, 7, 6, 5], co, [0, 0, 0, 0], 3);
        _cycle4(ep, [4, 7, 6, 5], eo, [0, 0, 0, 0], 2);
        break;
      case CubeFace.l:
        _cycle4(cp, [1, 5, 6, 2], co, [1, 2, 1, 2], 3);
        _cycle4(ep, [2, 9, 6, 10], eo, [0, 0, 0, 0], 2);
        break;
      case CubeFace.r:
        _cycle4(cp, [0, 3, 7, 4], co, [2, 1, 2, 1], 3);
        _cycle4(ep, [0, 11, 4, 8], eo, [0, 0, 0, 0], 2);
        break;
      case CubeFace.f:
        _cycle4(cp, [0, 4, 5, 1], co, [1, 2, 1, 2], 3);
        _cycle4(ep, [1, 8, 5, 9], eo, [1, 1, 1, 1], 2);
        break;
      case CubeFace.b:
        _cycle4(cp, [2, 6, 7, 3], co, [1, 2, 1, 2], 3);
        _cycle4(ep, [3, 10, 7, 11], eo, [1, 1, 1, 1], 2);
        break;
      default:
        break;
    }
  }

  void _cycle4(
      List<int> p, List<int> idx, List<int> o, List<int> oChange, int mod) {
    final tmpP = p[idx[3]];
    final tmpO = o[idx[3]];
    for (int i = 3; i > 0; i--) {
      p[idx[i]] = p[idx[i - 1]];
      o[idx[i]] = (o[idx[i - 1]] + oChange[i]) % mod;
    }
    p[idx[0]] = tmpP;
    o[idx[0]] = (tmpO + oChange[0]) % mod;
  }

  void rotateY(int turns) {
    int count = (turns % 4 + 4) % 4;
    for (int i = 0; i < count; i++) {
      _cycle4(cp, [0, 1, 2, 3], co, [0, 0, 0, 0], 3);
      _cycle4(cp, [4, 5, 6, 7], co, [0, 0, 0, 0], 3);
      _cycle4(ep, [0, 1, 2, 3], eo, [0, 0, 0, 0], 2);
      _cycle4(ep, [4, 5, 6, 7], eo, [0, 0, 0, 0], 2);
      _cycle4(ep, [8, 9, 10, 11], eo, [1, 1, 1, 1], 2);
    }
  }

  void rotateX(int turns) {
    int count = (turns % 4 + 4) % 4;
    for (int i = 0; i < count; i++) {
      _cycle4(cp, [0, 3, 7, 4], co, [2, 1, 2, 1], 3);
      _cycle4(cp, [1, 2, 6, 5], co, [1, 2, 1, 2], 3);
      _cycle4(ep, [0, 11, 4, 8], eo, [0, 0, 0, 0], 2);
      _cycle4(ep, [1, 3, 7, 5], eo, [1, 1, 1, 1], 2);
      _cycle4(ep, [2, 10, 6, 9], eo, [0, 0, 0, 0], 2);
    }
  }

  // --- Conversion and Extraction ---

  factory KociembaCube.fromCubeState(CubeState state) {
    final centers = {
      CubeFace.u: state.u[4],
      CubeFace.d: state.d[4],
      CubeFace.f: state.f[4],
      CubeFace.b: state.b[4],
      CubeFace.r: state.r[4],
      CubeFace.l: state.l[4],
    };
    final res = KociembaCube(centers);
    final stickers = state.allStickers;

    final cornerLookup = res._buildCornerLookup();
    final edgeLookup = res._buildEdgeLookup();
    final cColors = res.cornerColors;
    final eColors = res.edgeColors;

    // Corners
    for (final spot in Corner.values) {
      final ids = getCornerStickers(spot);
      int mask = 0;
      for (final id in ids) {
        mask |= (1 << stickers[id].index);
      }
      final p = cornerLookup[mask];
      if (p == null) {
        throw Exception(
            '[Solver] Invalid Corner at $spot. Mask: $mask. Colors: ${ids.map((id) => stickers[id]).toList()}');
      }
      res.cp[spot.index] = p;
      final primary = cColors[Corner.values[p]]![0];
      for (int i = 0; i < 3; i++) {
        if (stickers[ids[i]] == primary) {
          res.co[spot.index] = i;
          break;
        }
      }
    }
    // Edges
    for (final spot in Edge.values) {
      final ids = getEdgeStickers(spot);
      int mask = 0;
      for (final id in ids) {
        mask |= (1 << stickers[id].index);
      }
      final p = edgeLookup[mask];
      if (p == null) {
        throw Exception(
            '[Solver] Invalid Edge at $spot. Mask: $mask. Colors: ${ids.map((id) => stickers[id]).toList()}');
      }
      res.ep[spot.index] = p;
      final primary = eColors[Edge.values[p]]![0];
      res.eo[spot.index] = (stickers[ids[0]] == primary) ? 0 : 1;
    }
    return res;
  }

  CubeState toCubeState() {
    final state = CubeState.solved();
    for (int i = 0; i < 8; i++) {
      final pieceIdx = cp[i];
      final pieceColors = cornerColors[Corner.values[pieceIdx]]!;
      final spotIds = getCornerStickers(Corner.values[i]);
      final ori = co[i];
      for (int j = 0; j < 3; j++) {
        _setSticker(state, spotIds[(j + ori) % 3], pieceColors[j]);
      }
    }
    for (int i = 0; i < 12; i++) {
      final pieceIdx = ep[i];
      final pieceColors = edgeColors[Edge.values[pieceIdx]]!;
      final spotIds = getEdgeStickers(Edge.values[i]);
      final ori = eo[i];
      for (int j = 0; j < 2; j++) {
        _setSticker(state, spotIds[(j + ori) % 2], pieceColors[j]);
      }
    }
    return state;
  }

  void _setSticker(CubeState state, int id, CubeColor color) {
    final faceIdx = id ~/ 9;
    final stickerIdx = id % 9;
    switch (faceIdx) {
      case 0:
        state.u[stickerIdx] = color;
        break;
      case 1:
        state.d[stickerIdx] = color;
        break;
      case 2:
        state.f[stickerIdx] = color;
        break;
      case 3:
        state.b[stickerIdx] = color;
        break;
      case 4:
        state.r[stickerIdx] = color;
        break;
      case 5:
        state.l[stickerIdx] = color;
        break;
    }
  }

  // --- Phase 1 Coordinates ---

  int get twist {
    int res = 0;
    for (int i = 0; i < 7; i++) {
      res = res * 3 + co[i];
    }
    return res;
  }

  set twist(int v) {
    int parity = 0;
    for (int i = 6; i >= 0; i--) {
      co[i] = v % 3;
      parity += co[i];
      v = v ~/ 3;
    }
    co[7] = (3 - (parity % 3)) % 3;
  }

  int get flip {
    int res = 0;
    for (int i = 0; i < 11; i++) {
      res = res * 2 + eo[i];
    }
    return res;
  }

  set flip(int v) {
    int parity = 0;
    for (int i = 10; i >= 0; i--) {
      eo[i] = v % 2;
      parity += eo[i];
      v = v ~/ 2;
    }
    eo[11] = parity % 2;
  }

  int get slice {
    int res = 0;
    int k = 4;
    for (int i = 11; i >= 0; i--) {
      if (ep[i] >= 8) {
        res += _nCr(i, k--);
      }
    }
    return 494 - res;
  }

  set slice(int sliceIdx) {
    sliceIdx = 494 - sliceIdx;
    for (int i = 0; i < 12; i++) {
      ep[i] = -1;
    }
    int k = 4;
    final sliceEdges = [8, 9, 10, 11];
    final otherEdges = [0, 1, 2, 3, 4, 5, 6, 7];
    int otherIdx = 0;
    int sliceCount = 0;
    for (int i = 11; i >= 0; i--) {
      int c = _nCr(i, k);
      if (k > 0 && sliceIdx >= c) {
        sliceIdx -= c;
        ep[i] = sliceEdges[sliceCount++];
        k--;
      } else {
        if (otherIdx < 8) {
          ep[i] = otherEdges[otherIdx++];
        } else {
          ep[i] = sliceEdges[sliceCount++];
        }
      }
    }
  }

  // --- Phase 2 Coordinates ---

  int get cpRank => _getRank(cp);
  set cpRank(int v) => _setRank(cp, v, 8);

  int get epRank => _getRank(ep.sublist(0, 8));
  set epRank(int v) {
    final sub = List.generate(8, (_) => 0);
    _setRank(sub, v, 8);
    for (int i = 0; i < 8; i++) {
      ep[i] = sub[i];
    }
  }

  int get uspRank => _getRank(ep.sublist(8, 12).map((e) => e - 8).toList());
  set uspRank(int v) {
    final sub = List.generate(4, (_) => 0);
    _setRank(sub, v, 4);
    for (int i = 0; i < 4; i++) {
      ep[i + 8] = sub[i] + 8;
    }
  }

  // --- Helpers ---

  int _getRank(List<int> p) {
    int res = 0;
    for (int i = 0; i < p.length; i++) {
      int count = 0;
      for (int j = i + 1; j < p.length; j++) {
        if (p[j] < p[i]) {
          count++;
        }
      }
      res += count * _fact(p.length - 1 - i);
    }
    return res;
  }

  void _setRank(List<int> p, int rank, int n) {
    final available = List.generate(n, (i) => i);
    for (int i = 0; i < n; i++) {
      int f = _fact(n - 1 - i);
      int choice = rank ~/ f;
      p[i] = available.removeAt(choice);
      rank %= f;
    }
  }

  static int _fact(int n) {
    if (n <= 1) {
      return 1;
    }
    int res = 1;
    for (int i = 2; i <= n; i++) {
      res *= i;
    }
    return res;
  }

  static int _nCr(int n, int r) {
    if (n < r || r < 0) {
      return 0;
    }
    if (r == 0 || r == n) {
      return 1;
    }
    if (r > n / 2) {
      r = n - r;
    }
    int res = 1;
    for (int i = 1; i <= r; i++) {
      res = res * (n - i + 1) ~/ i;
    }
    return res;
  }

  static KociembaCube fromCoordinates(
      int tw, int fl, int sl, Map<CubeFace, CubeColor> centers) {
    final res = KociembaCube(centers);
    res.twist = tw;
    res.flip = fl;
    return res;
  }
}
