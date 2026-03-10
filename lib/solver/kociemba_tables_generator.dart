import 'dart:collection';
import 'kociemba_coordinates.dart';

class KociembaTableData {
  final List<List<int>> twistMove;
  final List<List<int>> flipMove;
  final List<List<int>> sliceMove;
  final List<List<int>> cpMove;
  final List<List<int>> epMove;
  final List<List<int>> uspMove;
  final List<int> twistSlicePrun;
  final List<int> flipSlicePrun;
  final List<int> cpUspPrun;
  final List<int> epUspPrun;

  KociembaTableData({
    required this.twistMove,
    required this.flipMove,
    required this.sliceMove,
    required this.cpMove,
    required this.epMove,
    required this.uspMove,
    required this.twistSlicePrun,
    required this.flipSlicePrun,
    required this.cpUspPrun,
    required this.epUspPrun,
  });
}

class KociembaTablesGenerator {
  static const int nTwist = 2187;
  static const int nFlip = 2048;
  static const int nSlice = 495;
  static const int nPerm = 40320; // 8!
  static const int nSlicePerm = 24; // 4!

  static KociembaTableData generateData() {
    final twistMove = List.generate(nTwist, (_) => List.filled(18, 0));
    final flipMove = List.generate(nFlip, (_) => List.filled(18, 0));
    final sliceMove = List.generate(nSlice, (_) => List.filled(18, 0));

    final cpMove = List.generate(nPerm, (_) => List.filled(10, 0));
    final epMove = List.generate(nPerm, (_) => List.filled(10, 0));
    final uspMove = List.generate(nSlicePerm, (_) => List.filled(10, 0));

    _initMoveTables(twistMove, flipMove, sliceMove, cpMove, epMove, uspMove);

    final twistSlicePrun = List.filled(nTwist * nSlice, -1);
    final flipSlicePrun = List.filled(nFlip * nSlice, -1);
    final cpUspPrun = List.filled(nPerm * nSlicePerm, -1);
    final epUspPrun = List.filled(nPerm * nSlicePerm, -1);

    _initPruningTables(
      twistMove,
      flipMove,
      sliceMove,
      cpMove,
      epMove,
      uspMove,
      twistSlicePrun,
      flipSlicePrun,
      cpUspPrun,
      epUspPrun,
    );

    return KociembaTableData(
      twistMove: twistMove,
      flipMove: flipMove,
      sliceMove: sliceMove,
      cpMove: cpMove,
      epMove: epMove,
      uspMove: uspMove,
      twistSlicePrun: twistSlicePrun,
      flipSlicePrun: flipSlicePrun,
      cpUspPrun: cpUspPrun,
      epUspPrun: epUspPrun,
    );
  }

  static void _initMoveTables(
    List<List<int>> twistMove,
    List<List<int>> flipMove,
    List<List<int>> sliceMove,
    List<List<int>> cpMove,
    List<List<int>> epMove,
    List<List<int>> uspMove,
  ) {
    _initMoveTablesPhase2(cpMove, epMove, uspMove);

    for (int i = 0; i < nTwist; i++) {
      for (int faceIdx = 0; faceIdx < 6; faceIdx++) {
        for (int t = 0; t < 3; t++) {
          final cube = KociembaCube();
          cube.twist = i;
          cube.applyMove(KociembaCube.allFaces[faceIdx], t + 1);
          twistMove[i][faceIdx * 3 + t] = cube.twist;
        }
      }
    }

    for (int i = 0; i < nFlip; i++) {
      for (int faceIdx = 0; faceIdx < 6; faceIdx++) {
        for (int t = 0; t < 3; t++) {
          final cube = KociembaCube();
          cube.flip = i;
          cube.applyMove(KociembaCube.allFaces[faceIdx], t + 1);
          flipMove[i][faceIdx * 3 + t] = cube.flip;
        }
      }
    }

    for (int i = 0; i < nSlice; i++) {
      for (int faceIdx = 0; faceIdx < 6; faceIdx++) {
        for (int t = 0; t < 3; t++) {
          final cube = KociembaCube();
          _setSliceInCube(cube, i);
          cube.applyMove(KociembaCube.allFaces[faceIdx], t + 1);
          sliceMove[i][faceIdx * 3 + t] = cube.slice;
        }
      }
    }
  }

  static void _setSliceInCube(KociembaCube cube, int sliceIdx) {
    sliceIdx = 494 - sliceIdx;
    for (int i = 0; i < 8; i++) {
      cube.cp[i] = i;
    }
    for (int i = 0; i < 8; i++) {
      cube.co[i] = 0;
    }
    for (int i = 0; i < 12; i++) {
      cube.ep[i] = -1;
    }
    for (int i = 0; i < 12; i++) {
      cube.eo[i] = 0;
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
        cube.ep[i] = sliceEdges[sliceCount++];
        k--;
      } else {
        if (otherIdx < 8) {
          cube.ep[i] = otherEdges[otherIdx++];
        } else {
          cube.ep[i] = sliceEdges[sliceCount++];
        }
      }
    }
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

  static const List<int> phase2AvailableMoves = [
    0,
    1,
    2,
    3,
    4,
    5,
    7,
    10,
    13,
    16
  ];

  static void _initMoveTablesPhase2(
    List<List<int>> cpMove,
    List<List<int>> epMove,
    List<List<int>> uspMove,
  ) {
    final cube = KociembaCube();
    for (int i = 0; i < nPerm; i++) {
      cube.cpRank = i;
      for (int m = 0; m < 10; m++) {
        int moveIdx = phase2AvailableMoves[m];
        cube.applyMove(KociembaCube.allFaces[moveIdx ~/ 3], (moveIdx % 3) + 1);
        cpMove[i][m] = cube.cpRank;
        cube.applyMove(
            KociembaCube.allFaces[moveIdx ~/ 3], 4 - ((moveIdx % 3) + 1));
      }
    }
    for (int i = 0; i < nPerm; i++) {
      cube.epRank = i;
      for (int m = 0; m < 10; m++) {
        int moveIdx = phase2AvailableMoves[m];
        cube.applyMove(KociembaCube.allFaces[moveIdx ~/ 3], (moveIdx % 3) + 1);
        epMove[i][m] = cube.epRank;
        cube.applyMove(
            KociembaCube.allFaces[moveIdx ~/ 3], 4 - ((moveIdx % 3) + 1));
      }
    }
    for (int i = 0; i < nSlicePerm; i++) {
      cube.uspRank = i;
      for (int m = 0; m < 10; m++) {
        int moveIdx = phase2AvailableMoves[m];
        cube.applyMove(KociembaCube.allFaces[moveIdx ~/ 3], (moveIdx % 3) + 1);
        uspMove[i][m] = cube.uspRank;
        cube.applyMove(
            KociembaCube.allFaces[moveIdx ~/ 3], 4 - ((moveIdx % 3) + 1));
      }
    }
  }

  static void _initPruningTables(
    List<List<int>> twistMove,
    List<List<int>> flipMove,
    List<List<int>> sliceMove,
    List<List<int>> cpMove,
    List<List<int>> epMove,
    List<List<int>> uspMove,
    List<int> twistSlicePrun,
    List<int> flipSlicePrun,
    List<int> cpUspPrun,
    List<int> epUspPrun,
  ) {
    final solved = KociembaCube();
    final sTwist = solved.twist;
    final sFlip = solved.flip;
    final sSlice = solved.slice;

    final queue = Queue<int>();

    twistSlicePrun[sTwist * nSlice + sSlice] = 0;
    queue.add(sTwist * nSlice + sSlice);
    while (queue.isNotEmpty) {
      final i = queue.removeFirst();
      final d = twistSlicePrun[i];
      final tw = i ~/ nSlice;
      final sl = i % nSlice;
      for (int m = 0; m < 18; m++) {
        final nextTw = twistMove[tw][m];
        final nextSl = sliceMove[sl][m];
        final nextIdx = nextTw * nSlice + nextSl;
        if (twistSlicePrun[nextIdx] == -1) {
          twistSlicePrun[nextIdx] = d + 1;
          queue.add(nextIdx);
        }
      }
    }

    queue.clear();
    flipSlicePrun[sFlip * nSlice + sSlice] = 0;
    queue.add(sFlip * nSlice + sSlice);
    while (queue.isNotEmpty) {
      final i = queue.removeFirst();
      final d = flipSlicePrun[i];
      final fl = i ~/ nSlice;
      final sl = i % nSlice;
      for (int m = 0; m < 18; m++) {
        final nextFl = flipMove[fl][m];
        final nextSl = sliceMove[sl][m];
        final nextIdx = nextFl * nSlice + nextSl;
        if (flipSlicePrun[nextIdx] == -1) {
          flipSlicePrun[nextIdx] = d + 1;
          queue.add(nextIdx);
        }
      }
    }

    queue.clear();
    cpUspPrun[0] = 0;
    queue.add(0);
    while (queue.isNotEmpty) {
      final i = queue.removeFirst();
      final d = cpUspPrun[i];
      final cpIdx = i ~/ nSlicePerm;
      final uspIdx = i % nSlicePerm;
      for (int m = 0; m < 10; m++) {
        final nextCp = cpMove[cpIdx][m];
        final nextUsp = uspMove[uspIdx][m];
        final nextIdx = nextCp * nSlicePerm + nextUsp;
        if (cpUspPrun[nextIdx] == -1) {
          cpUspPrun[nextIdx] = d + 1;
          queue.add(nextIdx);
        }
      }
    }

    queue.clear();
    epUspPrun[0] = 0;
    queue.add(0);
    while (queue.isNotEmpty) {
      final i = queue.removeFirst();
      final d = epUspPrun[i];
      final epIdx = i ~/ nSlicePerm;
      final uspIdx = i % nSlicePerm;
      for (int m = 0; m < 10; m++) {
        final nextEp = epMove[epIdx][m];
        final nextUsp = uspMove[uspIdx][m];
        final nextIdx = nextEp * nSlicePerm + nextUsp;
        if (epUspPrun[nextIdx] == -1) {
          epUspPrun[nextIdx] = d + 1;
          queue.add(nextIdx);
        }
      }
    }
  }
}
