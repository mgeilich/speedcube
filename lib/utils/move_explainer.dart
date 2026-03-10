import '../models/cube_move.dart';
import '../models/cube_state.dart';
import '../solver/kociemba_coordinates.dart';

/// Utility class to provide human-readable explanations and rationales for cube moves.
class MoveExplainer {
  /// Returns a human-readable description of what the move does.
  static String getDescription(CubeMove move) {
    final faceName = _getFaceFullName(move.face);
    final direction = _getDirectionDescription(move.turns);
    return "Rotate $faceName $direction";
  }

  /// Returns a short, high-level objective for this specific move.
  static String getObjective(
    CubeMove move,
    int phase,
    CubeState before,
    CubeState after,
  ) {
    if (phase == 1 && _isKociemba(before)) {
      final kBefore = KociembaCube.fromCubeState(before);
      final kAfter = KociembaCube.fromCubeState(after);

      if (kAfter.badEdgeCount < kBefore.badEdgeCount) {
        return "Orienting Edge";
      }
      if (kAfter.sliceCorrectCount > kBefore.sliceCorrectCount) {
        return "Aligning Slice";
      }
      return "Setup Move";
    } else {
      // Piece movement objective
      final keyInfo = _identifyKeyMovement(before, after);
      if (keyInfo != null) {
        if (keyInfo.sourcePosition == keyInfo.targetPosition) {
          return "Orient the ${keyInfo.pieceName} in its current slot";
        }
        return "Move ${keyInfo.pieceName} from ${keyInfo.sourcePosition} to ${keyInfo.targetPosition}";
      }
      return "Positioning Layer";
    }
  }

  /// Returns the high-level goal for a given Layer-by-Layer stage.
  static String getStageGoal(String stageName) {
    switch (stageName) {
      case 'White Cross':
        return "Create a white cross on the top face, matching the side colors with their centers.";
      case 'First Layer':
        return "Solve the four white corners to complete the first layer.";
      case 'Second Layer':
        return "Solve the four middle-layer edges to complete the first two layers.";
      case 'Yellow Cross':
        return "Orient the yellow edges on the top face to form a cross.";
      case 'Align Yellow Edges':
        return "Permute the yellow edges so they match the side centers.";
      case 'Yellow Corners':
        return "Position and orient the yellow corners to fully solve the cube.";
      default:
        return "Solve this step to move closer to the final state.";
    }
  }

  static bool _isKociemba(CubeState s) {
    // Rough check: if white center is Up, assume LBL or already oriented
    return s.getFace(CubeFace.u)[4] != CubeColor.white;
  }

  /// Returns a detailed rationale for the move, identifying specific pieces and positions.
  static String getRationale(
    CubeMove move,
    int moveIndex,
    int totalMoves,
    CubeState before,
    CubeState after, {
    int? phase,
  }) {
    final currentPhase = phase ?? (moveIndex < totalMoves / 2 ? 1 : 2);
    final keyInfo = _identifyKeyMovement(before, after);

    String specifics = "";
    if (keyInfo != null) {
      if (keyInfo.sourcePosition == keyInfo.targetPosition) {
        specifics =
            " It re-orients the ${keyInfo.pieceName} in its current slot.";
      } else {
        specifics =
            " It moves the ${keyInfo.pieceName} from ${keyInfo.sourcePosition} to ${keyInfo.targetPosition}.";
      }
    }

    if (currentPhase == 1) {
      final kBefore = KociembaCube.fromCubeState(before);
      final kAfter = KociembaCube.fromCubeState(after);

      final beBefore = kBefore.badEdgeCount;
      final beAfter = kAfter.badEdgeCount;
      final slBefore = kBefore.sliceCorrectCount;
      final slAfter = kAfter.sliceCorrectCount;

      if (beAfter < beBefore) {
        return "Phase 1 requires all 12 edges to be 'oriented' correctly. This turn flips ${beBefore - beAfter} badly oriented edges into their correct orientation.$specifics";
      } else if (slAfter > slBefore) {
        return "This move places an edge into the middle layer (UD-slice). Phase 2 can only start once all 4 middle edges are in this slice.$specifics";
      } else if (beAfter == beBefore && slAfter == slBefore) {
        // Rationale for U2 or setup moves
        String moveReason = "This is a setup move.";
        if (move.turns == 2 || move.turns == -2) {
          moveReason =
              "This 180° turn efficiently moves pieces to the opposite side of the cube.";
        }
        return "$moveReason It doesn't solve pieces directly but rearranges them so that a subsequent move can orient them or place them in the middle slice.";
      }

      if (beAfter == 0 && slAfter == 4) {
        return "The cube has reached the H-subgroup! Any remaining turns in this phase are used to optimize the transition to Phase 2.";
      }

      return "This move reduces the overall complexity of the cube, moving it closer to a state where orientation is locked.$specifics";
    } else {
      // Phase 2 Rationale
      String restrictionNote = "";
      if (move.face == CubeFace.f ||
          move.face == CubeFace.b ||
          move.face == CubeFace.r ||
          move.face == CubeFace.l) {
        if (move.turns.abs() == 2) {
          restrictionNote =
              " Note that only double turns (180°) are used on the side faces during this phase to avoid breaking the edge orientation achieved earlier.";
        }
      }

      if (keyInfo != null) {
        return "Now that orientation is locked, we are permuting pieces. This move solves the ${keyInfo.pieceName} into its final position.$restrictionNote";
      }

      return "The cube is in the simplified H-subgroup. We are rearranging the remaining pieces using only the following moves: U, D, L2, R2, F2, B2 — to reach the final solved state.$restrictionNote";
    }
  }

  static String _getFaceFullName(CubeFace face) {
    switch (face) {
      case CubeFace.u:
        return "Top";
      case CubeFace.d:
        return "Bottom";
      case CubeFace.f:
        return "Front";
      case CubeFace.b:
        return "Back";
      case CubeFace.r:
        return "Right";
      case CubeFace.l:
        return "Left";
    }
  }

  static String _getDirectionDescription(int turns) {
    switch (turns) {
      case 1:
        return "90° clockwise";
      case -1:
        return "90° counter-clockwise";
      case 2:
        return "180°";
      default:
        return "rotation";
    }
  }

  static _MovementRecord? _identifyKeyMovement(
      CubeState before, CubeState after) {
    // Track which piece was moved by identifying which slot changed and finding where it went

    // 1. Find a piece that moved. We check all slots.
    // We prioritize pieces that are now SOLVED or in a KEY position.

    // Check edges
    for (final slot in _edgeSlots) {
      if (!_isEdgeEqual(before, after, slot)) {
        // This slot changed. Let's see what piece is here now.
        final currentPiece = _getEdgeColors(after, slot);
        // Find where this piece was before
        final prevSlot = _findEdgeByColors(before, currentPiece);
        if (prevSlot != null) {
          return _MovementRecord(
            pieceName: _getEdgeNameFromColors(currentPiece),
            sourcePosition: _getSlotPositionAbbr(prevSlot),
            targetPosition: _getSlotPositionAbbr(slot),
          );
        }
      }
    }

    // Check corners
    for (final slot in _cornerSlots) {
      if (!_isCornerEqual(before, after, slot)) {
        final currentPiece = _getCornerColors(after, slot);
        final prevSlot = _findCornerByColors(before, currentPiece);
        if (prevSlot != null) {
          return _MovementRecord(
            pieceName: _getCornerNameFromColors(currentPiece),
            sourcePosition: _getSlotPositionAbbr(prevSlot),
            targetPosition: _getSlotPositionAbbr(slot),
          );
        }
      }
    }

    return null;
  }

  static bool _isEdgeEqual(CubeState s1, CubeState s2, _Slot slot) {
    return s1.getFace(slot.face1)[slot.idx1] ==
            s2.getFace(slot.face1)[slot.idx1] &&
        s1.getFace(slot.face2)[slot.idx2] == s2.getFace(slot.face2)[slot.idx2];
  }

  static bool _isCornerEqual(CubeState s1, CubeState s2, _Slot slot) {
    return s1.getFace(slot.face1)[slot.idx1] ==
            s2.getFace(slot.face1)[slot.idx1] &&
        s1.getFace(slot.face2)[slot.idx2] ==
            s2.getFace(slot.face2)[slot.idx2] &&
        s1.getFace(slot.face3!)[slot.idx3!] ==
            s2.getFace(slot.face3!)[slot.idx3!];
  }

  static Set<CubeColor> _getEdgeColors(CubeState s, _Slot slot) {
    return {s.getFace(slot.face1)[slot.idx1], s.getFace(slot.face2)[slot.idx2]};
  }

  static Set<CubeColor> _getCornerColors(CubeState s, _Slot slot) {
    return {
      s.getFace(slot.face1)[slot.idx1],
      s.getFace(slot.face2)[slot.idx2],
      s.getFace(slot.face3!)[slot.idx3!]
    };
  }

  static _Slot? _findEdgeByColors(CubeState s, Set<CubeColor> colors) {
    for (final slot in _edgeSlots) {
      if (_getEdgeColors(s, slot).containsAll(colors)) return slot;
    }
    return null;
  }

  static _Slot? _findCornerByColors(CubeState s, Set<CubeColor> colors) {
    for (final slot in _cornerSlots) {
      if (_getCornerColors(s, slot).containsAll(colors)) return slot;
    }
    return null;
  }

  static String _getEdgeNameFromColors(Set<CubeColor> colors) {
    final list = colors.toList();
    return "${_getColorName(list[0])}-${_getColorName(list[1])} edge";
  }

  static String _getCornerNameFromColors(Set<CubeColor> colors) {
    final list = colors.toList();
    return "${_getColorName(list[0])}-${_getColorName(list[1])}-${_getColorName(list[2])} corner";
  }

  static String _getSlotPositionAbbr(_Slot slot) {
    final f1 = _getFaceAbbr(slot.face1);
    final f2 = _getFaceAbbr(slot.face2);
    if (slot.face3 != null) {
      final f3 = _getFaceAbbr(slot.face3!);
      return "$f1$f2$f3";
    }
    return "$f1$f2";
  }

  static String _getFaceAbbr(CubeFace face) {
    switch (face) {
      case CubeFace.u:
        return "Top";
      case CubeFace.d:
        return "Bottom";
      case CubeFace.f:
        return "Front";
      case CubeFace.b:
        return "Back";
      case CubeFace.r:
        return "Right";
      case CubeFace.l:
        return "Left";
    }
  }

  static String _getColorName(CubeColor color) {
    switch (color) {
      case CubeColor.white:
        return "White";
      case CubeColor.yellow:
        return "Yellow";
      case CubeColor.green:
        return "Green";
      case CubeColor.blue:
        return "Blue";
      case CubeColor.red:
        return "Red";
      case CubeColor.orange:
        return "Orange";
    }
  }

  // Slot definitions
  static final List<_Slot> _edgeSlots = [
    _Slot(CubeFace.u, 1, CubeFace.b, 1),
    _Slot(CubeFace.u, 3, CubeFace.l, 1),
    _Slot(CubeFace.u, 5, CubeFace.r, 1),
    _Slot(CubeFace.u, 7, CubeFace.f, 1),
    _Slot(CubeFace.d, 1, CubeFace.f, 7),
    _Slot(CubeFace.d, 3, CubeFace.l, 7),
    _Slot(CubeFace.d, 5, CubeFace.r, 7),
    _Slot(CubeFace.d, 7, CubeFace.b, 7),
    _Slot(CubeFace.f, 3, CubeFace.l, 5),
    _Slot(CubeFace.f, 5, CubeFace.r, 3),
    _Slot(CubeFace.b, 3, CubeFace.r, 5),
    _Slot(CubeFace.b, 5, CubeFace.l, 3),
  ];

  static final List<_Slot> _cornerSlots = [
    _Slot(CubeFace.u, 0, CubeFace.b, 2, CubeFace.l, 0),
    _Slot(CubeFace.u, 2, CubeFace.r, 2, CubeFace.b, 0),
    _Slot(CubeFace.u, 6, CubeFace.l, 2, CubeFace.f, 0),
    _Slot(CubeFace.u, 8, CubeFace.f, 2, CubeFace.r, 0),
    _Slot(CubeFace.d, 0, CubeFace.f, 6, CubeFace.l, 8),
    _Slot(CubeFace.d, 2, CubeFace.r, 6, CubeFace.f, 8),
    _Slot(CubeFace.d, 6, CubeFace.l, 6, CubeFace.b, 8),
    _Slot(CubeFace.d, 8, CubeFace.b, 6, CubeFace.r, 8),
  ];
}

class _Slot {
  final CubeFace face1;
  final int idx1;
  final CubeFace face2;
  final int idx2;
  final CubeFace? face3;
  final int? idx3;

  _Slot(this.face1, this.idx1, this.face2, this.idx2, [this.face3, this.idx3]);
}

class _MovementRecord {
  final String pieceName;
  final String sourcePosition;
  final String targetPosition;
  _MovementRecord({
    required this.pieceName,
    required this.sourcePosition,
    required this.targetPosition,
  });
}
