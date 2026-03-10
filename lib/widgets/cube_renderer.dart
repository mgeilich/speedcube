import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/cube_state.dart';
import '../models/cube_move.dart';

/// 3D vector/point
class Vec3 {
  double x, y, z;
  Vec3(this.x, this.y, this.z);

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);

  Vec3 rotateX(double a) {
    final c = math.cos(a), s = math.sin(a);
    return Vec3(x, y * c - z * s, y * s + z * c);
  }

  Vec3 rotateY(double a) {
    final c = math.cos(a), s = math.sin(a);
    return Vec3(x * c + z * s, y, -x * s + z * c);
  }

  Vec3 rotateZ(double a) {
    final c = math.cos(a), s = math.sin(a);
    return Vec3(x * c - y * s, x * s + y * c, z);
  }

  Vec3 clone() => Vec3(x, y, z);

  Offset project(double dist, double scale, Offset center) {
    final f = dist / (dist - z);
    return Offset(center.dx + x * scale * f, center.dy - y * scale * f);
  }
}

/// A polygon face with its parent cubie position
class Polygon {
  List<Vec3> verts;
  final Color color;
  final int cubieX, cubieY, cubieZ;
  final bool isSticker;
  final CubeFace? stickerFace;
  final int? stickerIndex;
  final String? label;
  double depth = 0;

  Polygon(this.verts, this.color, this.cubieX, this.cubieY, this.cubieZ,
      {this.isSticker = false,
      this.stickerFace,
      this.stickerIndex,
      this.label});

  void calcDepth() {
    double sumZ = 0;
    for (final v in verts) {
      sumZ += v.z;
    }
    depth = (sumZ / verts.length) + (isSticker ? 0.1 : 0.0);
  }

  Vec3 normal() {
    final v0 = verts[0];
    final v1 = verts[verts.length > 4 ? 4 : 1];
    final v2 = verts[verts.length > 8 ? 8 : 2];

    final a = v1 - v0;
    final b = v2 - v0;
    final nx = a.y * b.z - a.z * b.y;
    final ny = a.z * b.x - a.x * b.z;
    final nz = a.x * b.y - a.y * b.x;
    final len = math.sqrt(nx * nx + ny * ny + nz * nz);
    return len > 0 ? Vec3(nx / len, ny / len, nz / len) : Vec3(0, 0, 1);
  }

  bool isOnSlice(CubeFace face) {
    switch (face) {
      case CubeFace.u:
        return cubieY == 1;
      case CubeFace.d:
        return cubieY == -1;
      case CubeFace.r:
        return cubieX == 1;
      case CubeFace.l:
        return cubieX == -1;
      case CubeFace.f:
        return cubieZ == 1;
      case CubeFace.b:
        return cubieZ == -1;
    }
  }
}

enum HighlightPieceType { all, edges, corners, centers, udSliceEdges }

class CubeRenderer extends CustomPainter {
  final CubeState cubeState;
  final double rotationX;
  final double rotationY;
  final CubeMove? animatingMove;
  final double animationProgress;
  final CubeFace? highlightedFace;
  final bool ghostMode;
  final HighlightPieceType highlightPieceType;
  final Map<CubeFace, Map<int, String>>? stickerLabels;
  final List<MapEntry<CubeFace, int>>? highlightedStickers;
  final List<MapEntry<CubeFace, int>>? availableStickers;
  final bool dimNonHighlighted;

  CubeRenderer({
    required this.cubeState,
    this.rotationX = -0.5,
    this.rotationY = 0.7,
    this.animatingMove,
    this.animationProgress = 0.0,
    this.highlightedFace,
    this.ghostMode = false,
    this.highlightPieceType = HighlightPieceType.all,
    this.stickerLabels,
    this.highlightedStickers,
    this.availableStickers,
    this.dimNonHighlighted = false,
  });

  static const _colors = {
    CubeColor.white: Color(0xFFF8F9FA),
    CubeColor.yellow: Color(0xFFFFD60A),
    CubeColor.green: Color(0xFF34C759),
    CubeColor.blue: Color(0xFF007AFF),
    CubeColor.red: Color(0xFFFF3B30),
    CubeColor.orange: Color(0xFFFF9500),
  };

  static const _black = Color(0xFF0A0A0A);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = math.min(size.width, size.height) * 0.15;
    const dist = 10.0;

    final polys = <Polygon>[];
    for (int cx = -1; cx <= 1; cx++) {
      for (int cy = -1; cy <= 1; cy++) {
        for (int cz = -1; cz <= 1; cz++) {
          _buildCubie(polys, cx.toDouble(), cy.toDouble(), cz.toDouble());
        }
      }
    }

    for (final poly in polys) {
      final onSlice =
          animatingMove != null && poly.isOnSlice(animatingMove!.face);
      poly.verts = poly.verts.map((v) {
        var p = v.clone();
        if (onSlice) p = _applyMove(p, animatingMove!, animationProgress);
        p = p.rotateY(rotationY).rotateX(rotationX);
        return p;
      }).toList();
      poly.calcDepth();
    }

    polys.sort((a, b) => a.depth.compareTo(b.depth));

    for (final poly in polys) {
      final n = poly.normal();
      if (n.z < 0.0) continue;

      final pts =
          poly.verts.map((v) => v.project(dist, scale, center)).toList();
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      path.close();

      if (poly.isSticker) {
        final light = n.z;
        final bright = 0.8 + 0.2 * light;
        var shaded = Color.lerp(Colors.black, poly.color, bright)!;

        final isSpecificHighlight = highlightedStickers?.any((e) =>
                e.key == poly.stickerFace && e.value == poly.stickerIndex) ??
            false;

        final isAvailable = availableStickers?.any((e) =>
                e.key == poly.stickerFace && e.value == poly.stickerIndex) ??
            false;

        if (isSpecificHighlight) {
          shaded = Color.lerp(shaded, Colors.white, 0.4)!;
        } else if (isAvailable) {
          shaded = Color.lerp(shaded, Colors.white, 0.15)!;
        } else if (dimNonHighlighted && highlightedStickers != null) {
          shaded = shaded.withValues(alpha: 0.2);
        }

        final rect = path.getBounds();
        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(Colors.white, shaded, 0.2)!,
              shaded,
              Color.lerp(Colors.black, shaded, 0.8)!,
            ],
            stops: const [0.0, 0.3, 1.0],
          ).createShader(rect)
          ..isAntiAlias = true;

        canvas.drawPath(path, paint);

        if (isSpecificHighlight) {
          final glowPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
          canvas.drawPath(path, glowPaint);
        } else if (isAvailable) {
          final availablePaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;
          canvas.drawPath(path, availablePaint);
        }

        if (n.z > 0.4) {
          final specOpacity = math.pow(n.z, 12).toDouble().clamp(0.0, 0.3);
          canvas.drawPath(
              path,
              Paint()
                ..color = Colors.white.withValues(alpha: specOpacity)
                ..isAntiAlias = true);
        }

        if (poly.label != null) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: poly.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                      blurRadius: 3, color: Colors.black, offset: Offset(1, 1))
                ],
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          final centerPos = pts.reduce((a, b) => a + b) / pts.length.toDouble();
          textPainter.paint(
              canvas,
              centerPos -
                  Offset(textPainter.width / 2, textPainter.height / 2));
        }
      } else {
        final light = n.z;
        final bright = 0.3 + 0.5 * light;
        final baseColor =
            ghostMode ? Colors.white.withValues(alpha: 0.05) : _black;
        final shaded = Color.lerp(Colors.black, baseColor, bright)!;
        canvas.drawPath(
            path,
            Paint()
              ..color = shaded
              ..isAntiAlias = true);
      }
    }
  }

  void _buildCubie(List<Polygon> polys, double cx, double cy, double cz) {
    const s = 0.5;
    const stSize = 0.45;
    const stRadius = 0.08;
    const stOff = 0.01;

    if (cy == 1.0) {
      _addFace(polys, cx, cy, cz, s, CubeFace.u, false);
      _addFace(polys, cx, cy, cz, stSize, CubeFace.u, true,
          stOff: stOff, stRadius: stRadius);
    }
    if (cy == -1.0) {
      _addFace(polys, cx, cy, cz, s, CubeFace.d, false);
      _addFace(polys, cx, cy, cz, stSize, CubeFace.d, true,
          stOff: stOff, stRadius: stRadius);
    }
    if (cz == 1.0) {
      _addFace(polys, cx, cy, cz, s, CubeFace.f, false);
      _addFace(polys, cx, cy, cz, stSize, CubeFace.f, true,
          stOff: stOff, stRadius: stRadius);
    }
    if (cz == -1.0) {
      _addFace(polys, cx, cy, cz, s, CubeFace.b, false);
      _addFace(polys, cx, cy, cz, stSize, CubeFace.b, true,
          stOff: stOff, stRadius: stRadius);
    }
    if (cx == 1.0) {
      _addFace(polys, cx, cy, cz, s, CubeFace.r, false);
      _addFace(polys, cx, cy, cz, stSize, CubeFace.r, true,
          stOff: stOff, stRadius: stRadius);
    }
    if (cx == -1.0) {
      _addFace(polys, cx, cy, cz, s, CubeFace.l, false);
      _addFace(polys, cx, cy, cz, stSize, CubeFace.l, true,
          stOff: stOff, stRadius: stRadius);
    }
  }

  void _addFace(List<Polygon> polys, double cx, double cy, double cz, double s,
      CubeFace face, bool isSticker,
      {double stOff = 0, double stRadius = 0}) {
    final label = isSticker
        ? _getStickerLabel(face, cx.toInt(), cy.toInt(), cz.toInt())
        : null;
    final color = isSticker
        ? _getStickerColor(face, cx.toInt(), cy.toInt(), cz.toInt())
        : _black;
    final off = 0.5 + stOff;
    final List<Vec3> verts;

    if (isSticker) {
      final corners = [
        Offset(-s + stRadius, -s),
        Offset(s - stRadius, -s),
        Offset(s, -s + stRadius),
        Offset(s, s - stRadius),
        Offset(s - stRadius, s),
        Offset(-s + stRadius, s),
        Offset(-s, s - stRadius),
        Offset(-s, -s + stRadius),
      ];
      final points = <Offset>[];
      for (int i = 0; i < 8; i += 2) {
        points.add(corners[i]);
        points.add(Offset(
            corners[i].dx + (corners[i + 1].dx - corners[i].dx) * 0.5,
            corners[i].dy + (corners[i + 1].dy - corners[i].dy) * 0.5));
        points.add(corners[i + 1]);
      }
      verts = points.map((p) {
        switch (face) {
          case CubeFace.u:
            return Vec3(cx + p.dx, cy + off, cz - p.dy);
          case CubeFace.d:
            return Vec3(cx + p.dx, cy - off, cz + p.dy);
          case CubeFace.f:
            return Vec3(cx + p.dx, cy + p.dy, cz + off);
          case CubeFace.b:
            return Vec3(cx - p.dx, cy + p.dy, cz - off);
          case CubeFace.r:
            return Vec3(cx + off, cy + p.dy, cz - p.dx);
          case CubeFace.l:
            return Vec3(cx - off, cy + p.dy, cz + p.dx);
        }
      }).toList();
    } else {
      switch (face) {
        case CubeFace.u:
          verts = [
            Vec3(cx - s, cy + s, cz + s),
            Vec3(cx + s, cy + s, cz + s),
            Vec3(cx + s, cy + s, cz - s),
            Vec3(cx - s, cy + s, cz - s)
          ];
          break;
        case CubeFace.d:
          verts = [
            Vec3(cx - s, cy - s, cz - s),
            Vec3(cx + s, cy - s, cz - s),
            Vec3(cx + s, cy - s, cz + s),
            Vec3(cx - s, cy - s, cz + s)
          ];
          break;
        case CubeFace.f:
          verts = [
            Vec3(cx - s, cy - s, cz + s),
            Vec3(cx + s, cy - s, cz + s),
            Vec3(cx + s, cy + s, cz + s),
            Vec3(cx - s, cy + s, cz + s)
          ];
          break;
        case CubeFace.b:
          verts = [
            Vec3(cx + s, cy - s, cz - s),
            Vec3(cx - s, cy - s, cz - s),
            Vec3(cx - s, cy + s, cz - s),
            Vec3(cx + s, cy + s, cz - s)
          ];
          break;
        case CubeFace.r:
          verts = [
            Vec3(cx + s, cy - s, cz + s),
            Vec3(cx + s, cy - s, cz - s),
            Vec3(cx + s, cy + s, cz - s),
            Vec3(cx + s, cy + s, cz + s)
          ];
          break;
        case CubeFace.l:
          verts = [
            Vec3(cx - s, cy - s, cz - s),
            Vec3(cx - s, cy - s, cz + s),
            Vec3(cx - s, cy + s, cz + s),
            Vec3(cx - s, cy + s, cz - s)
          ];
          break;
      }
    }
    polys.add(Polygon(verts, color, cx.toInt(), cy.toInt(), cz.toInt(),
        isSticker: isSticker,
        stickerFace: isSticker ? face : null,
        stickerIndex: isSticker
            ? _getRowCol(face, cx.toInt(), cy.toInt(), cz.toInt())
                .let((rc) => rc.dy.toInt() * 3 + rc.dx.toInt())
            : null,
        label: label));
  }

  Color _getStickerColor(CubeFace face, int cx, int cy, int cz) {
    final rowCol = _getRowCol(face, cx, cy, cz);
    final index = rowCol.dy.toInt() * 3 + rowCol.dx.toInt();
    final color = cubeState.getFace(face)[index];

    if (ghostMode) {
      final isTargetCenter =
          index == 4 && (face == CubeFace.f || face == CubeFace.u);
      if (!isTargetCenter) return Colors.white.withValues(alpha: 0.1);
    }

    if (highlightPieceType != HighlightPieceType.all) {
      final absX = cx.abs();
      final absY = cy.abs();
      final absZ = cz.abs();
      final pieceSum = absX + absY + absZ;
      bool isMatch = false;
      switch (highlightPieceType) {
        case HighlightPieceType.edges:
          isMatch = pieceSum == 2;
          break;
        case HighlightPieceType.corners:
          isMatch = pieceSum == 3;
          break;
        case HighlightPieceType.centers:
          isMatch = pieceSum == 1;
          break;
        case HighlightPieceType.udSliceEdges:
          isMatch = pieceSum == 2 && absY == 0;
          break;
        default:
          isMatch = true;
      }
      if (!isMatch) return Colors.white.withValues(alpha: 0.05);
    }
    return _colors[color]!;
  }

  String? _getStickerLabel(CubeFace face, int cx, int cy, int cz) {
    if (stickerLabels == null) return null;
    final rowCol = _getRowCol(face, cx, cy, cz);
    final index = rowCol.dy.toInt() * 3 + rowCol.dx.toInt();
    return stickerLabels![face]?[index];
  }

  Offset _getRowCol(CubeFace face, int cx, int cy, int cz) {
    int row, col;
    switch (face) {
      case CubeFace.u:
        col = cx + 1;
        row = cz + 1;
        break;
      case CubeFace.d:
        col = cx + 1;
        row = 1 - cz;
        break;
      case CubeFace.f:
        col = cx + 1;
        row = 1 - cy;
        break;
      case CubeFace.b:
        col = 1 - cx;
        row = 1 - cy;
        break;
      case CubeFace.r:
        col = 1 - cz;
        row = 1 - cy;
        break;
      case CubeFace.l:
        col = cz + 1;
        row = 1 - cy;
        break;
    }
    return Offset(col.toDouble(), row.toDouble());
  }

  Vec3 _applyMove(Vec3 p, CubeMove move, double progress) {
    final angle = move.angle * progress;
    switch (move.face) {
      case CubeFace.u:
        return p.rotateY(-angle);
      case CubeFace.d:
        return p.rotateY(angle);
      case CubeFace.r:
        return p.rotateX(-angle);
      case CubeFace.l:
        return p.rotateX(angle);
      case CubeFace.f:
        return p.rotateZ(-angle);
      case CubeFace.b:
        return p.rotateZ(angle);
    }
  }

  MapEntry<CubeFace, int>? hitTestSticker(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = math.min(size.width, size.height) * 0.15;
    const dist = 10.0;
    final polys = <Polygon>[];
    for (int cx = -1; cx <= 1; cx++) {
      for (int cy = -1; cy <= 1; cy++) {
        for (int cz = -1; cz <= 1; cz++) {
          _buildCubie(polys, cx.toDouble(), cy.toDouble(), cz.toDouble());
        }
      }
    }
    final stickerPolys = polys.where((p) => p.isSticker).toList();
    for (final poly in stickerPolys) {
      poly.verts = poly.verts.map((v) {
        var p = v.clone();
        p = p.rotateY(rotationY).rotateX(rotationX);
        return p;
      }).toList();
      poly.calcDepth();
    }
    stickerPolys.sort((a, b) => b.depth.compareTo(a.depth));
    for (final poly in stickerPolys) {
      final n = poly.normal();
      if (n.z < 0.0) {
        continue;
      }
      final pts =
          poly.verts.map((v) => v.project(dist, scale, center)).toList();
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      path.close();
      if (path.contains(localPosition)) {
        return MapEntry(poly.stickerFace!, poly.stickerIndex!);
      }
    }
    return null;
  }

  @override
  bool shouldRepaint(CubeRenderer old) =>
      cubeState != old.cubeState ||
      rotationX != old.rotationX ||
      rotationY != old.rotationY ||
      animatingMove != old.animatingMove ||
      animationProgress != old.animationProgress ||
      highlightedFace != old.highlightedFace ||
      ghostMode != old.ghostMode ||
      highlightPieceType != old.highlightPieceType ||
      stickerLabels != old.stickerLabels ||
      highlightedStickers != old.highlightedStickers ||
      availableStickers != old.availableStickers ||
      dimNonHighlighted != old.dimNonHighlighted;
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
