import '../models/cube_move.dart';

class PiecePathSolver {
  static List<CubeMove>? findPath({
    required CubeFace startFace,
    required int startIndex,
    required CubeFace targetFace,
    required int targetIndex,
  }) {
    if (startFace == targetFace && startIndex == targetIndex) {
      return [];
    }

    // Check if they are in the same orbit
    if (!_areInSameOrbit(startIndex, targetIndex)) {
      return null;
    }

    final targetPos = _StickerPos(targetFace, targetIndex);

    final queue = <_PathNode>[
      _PathNode(_StickerPos(startFace, startIndex), [])
    ];
    final visited = <int>{_posToId(startFace, startIndex)};

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);

      // Heuristic: don't go too deep for simple paths
      if (current.path.length > 8) continue;

      for (final move in CubeMove.allMoves) {
        final nextPos = _applyMove(current.pos, move);
        final nextId = _posToId(nextPos.face, nextPos.index);

        if (nextPos.face == targetPos.face &&
            nextPos.index == targetPos.index) {
          return [...current.path, move];
        }

        if (!visited.contains(nextId)) {
          visited.add(nextId);
          queue.add(_PathNode(nextPos, [...current.path, move]));
        }
      }
    }

    return null;
  }

  static List<CubeMove>? findPreservingPath({
    required CubeFace startFace,
    required int startIndex,
    required CubeFace targetFace,
    required int targetIndex,
    required List<MapEntry<CubeFace, int>> preservedStickers,
  }) {
    if (startFace == targetFace && startIndex == targetIndex) {
      return [];
    }

    if (!_areInSameOrbit(startIndex, targetIndex)) {
      return null;
    }

    final startPositions = [
      _StickerPos(startFace, startIndex),
      ...preservedStickers.map((e) => _StickerPos(e.key, e.value)),
    ];

    final targetPositions = [
      _StickerPos(targetFace, targetIndex),
      ...preservedStickers.map((e) => _StickerPos(e.key, e.value)),
    ];

    final queue = <_MultiPathNode>[_MultiPathNode(startPositions, [])];
    final visited = <String>{_positionsToId(startPositions)};

    // BFS with a depth limit for performance
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);

      if (current.path.length > 7) continue;

      for (final move in CubeMove.allMoves) {
        final nextPositions =
            current.positions.map((p) => _applyMove(p, move)).toList();
        final nextId = _positionsToId(nextPositions);

        if (_isMatch(nextPositions, targetPositions)) {
          return [...current.path, move];
        }

        if (!visited.contains(nextId)) {
          visited.add(nextId);
          queue.add(_MultiPathNode(nextPositions, [...current.path, move]));
        }
      }
    }

    // If no path found within limit, fall back to simple path
    return findPath(
      startFace: startFace,
      startIndex: startIndex,
      targetFace: targetFace,
      targetIndex: targetIndex,
    );
  }

  static bool _isMatch(List<_StickerPos> p1, List<_StickerPos> p2) {
    for (int i = 0; i < p1.length; i++) {
      if (p1[i].face != p2[i].face || p1[i].index != p2[i].index) return false;
    }
    return true;
  }

  static String _positionsToId(List<_StickerPos> positions) {
    return positions.map((p) => "${p.face.index}${p.index}").join();
  }

  static bool _areInSameOrbit(int idx1, int idx2) {
    final type1 = _getPieceType(idx1);
    final type2 = _getPieceType(idx2);
    return type1 == type2;
  }

  static _PieceType _getPieceType(int index) {
    if (index == 4) {
      return _PieceType.center;
    }
    if ([1, 3, 5, 7].contains(index)) {
      return _PieceType.edge;
    }
    return _PieceType.corner;
  }

  static int _posToId(CubeFace face, int index) => face.index * 9 + index;

  static _StickerPos _applyMove(_StickerPos pos, CubeMove move) {
    final tracker = _TrackerState.one(pos.face, pos.index);
    final nextState = tracker.applyMove(move);
    return nextState.getPos();
  }
}

class _MultiPathNode {
  final List<_StickerPos> positions;
  final List<CubeMove> path;
  _MultiPathNode(this.positions, this.path);
}

enum _PieceType { corner, edge, center }

class _StickerPos {
  final CubeFace face;
  final int index;
  _StickerPos(this.face, this.index);
}

class _PathNode {
  final _StickerPos pos;
  final List<CubeMove> path;
  _PathNode(this.pos, this.path);
}

class _TrackerState {
  final Map<CubeFace, List<bool>> faces;

  _TrackerState(this.faces);

  factory _TrackerState.one(CubeFace face, int index) {
    final faces = {
      for (final f in CubeFace.values) f: List<bool>.filled(9, false),
    };
    faces[face]![index] = true;
    return _TrackerState(faces);
  }

  _StickerPos getPos() {
    for (final face in CubeFace.values) {
      for (int i = 0; i < 9; i++) {
        if (faces[face]![i]) {
          return _StickerPos(face, i);
        }
      }
    }
    throw StateError("Sticker lost!");
  }

  _TrackerState applyMove(CubeMove move) {
    final nextFaces = {
      for (final f in CubeFace.values) f: List<bool>.from(faces[f]!),
    };

    int turns = move.turns;
    if (turns == -1) {
      turns = 3;
    }

    for (int i = 0; i < turns; i++) {
      _applyQuarterTurn(nextFaces, move.face);
    }
    return _TrackerState(nextFaces);
  }

  void _applyQuarterTurn(Map<CubeFace, List<bool>> fMap, CubeFace face) {
    final faceList = fMap[face]!;
    _rotateFace(faceList);

    switch (face) {
      case CubeFace.u:
        _cycle(fMap[CubeFace.f]!, [0, 1, 2], fMap[CubeFace.l]!, [0, 1, 2],
            fMap[CubeFace.b]!, [0, 1, 2], fMap[CubeFace.r]!, [0, 1, 2]);
        break;
      case CubeFace.d:
        _cycle(fMap[CubeFace.f]!, [6, 7, 8], fMap[CubeFace.r]!, [6, 7, 8],
            fMap[CubeFace.b]!, [6, 7, 8], fMap[CubeFace.l]!, [6, 7, 8]);
        break;
      case CubeFace.f:
        _cycle(fMap[CubeFace.u]!, [6, 7, 8], fMap[CubeFace.r]!, [0, 3, 6],
            fMap[CubeFace.d]!, [2, 1, 0], fMap[CubeFace.l]!, [8, 5, 2]);
        break;
      case CubeFace.b:
        _cycle(fMap[CubeFace.u]!, [2, 1, 0], fMap[CubeFace.l]!, [0, 3, 6],
            fMap[CubeFace.d]!, [6, 7, 8], fMap[CubeFace.r]!, [8, 5, 2]);
        break;
      case CubeFace.r:
        _cycle(fMap[CubeFace.u]!, [2, 5, 8], fMap[CubeFace.b]!, [6, 3, 0],
            fMap[CubeFace.d]!, [2, 5, 8], fMap[CubeFace.f]!, [2, 5, 8]);
        break;
      case CubeFace.l:
        _cycle(fMap[CubeFace.u]!, [0, 3, 6], fMap[CubeFace.f]!, [0, 3, 6],
            fMap[CubeFace.d]!, [0, 3, 6], fMap[CubeFace.b]!, [8, 5, 2]);
        break;
    }
  }

  void _rotateFace(List<bool> face) {
    final temp = List<bool>.from(face);
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

  void _cycle(List<bool> p1, List<int> i1, List<bool> p2, List<int> i2,
      List<bool> p3, List<int> i3, List<bool> p4, List<int> i4) {
    for (int i = 0; i < 3; i++) {
      final temp = p1[i1[i]];
      p1[i1[i]] = p4[i4[i]];
      p4[i4[i]] = p3[i3[i]];
      p3[i3[i]] = p2[i2[i]];
      p2[i2[i]] = temp;
    }
  }
}
