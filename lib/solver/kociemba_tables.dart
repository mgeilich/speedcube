import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

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

class KociembaTables {
  static const int nTwist = 2187;
  static const int nFlip = 2048;
  static const int nSlice = 495;
  static const int nPerm = 40320; // 8!
  static const int nSlicePerm = 24; // 4!

  static KociembaTableData? _data;
  static Future<void>? _initFuture;

  static List<List<int>> get twistMove => _data!.twistMove;
  static List<List<int>> get flipMove => _data!.flipMove;
  static List<List<int>> get sliceMove => _data!.sliceMove;
  static List<List<int>> get cpMove => _data!.cpMove;
  static List<List<int>> get epMove => _data!.epMove;
  static List<List<int>> get uspMove => _data!.uspMove;
  static List<int> get twistSlicePrun => _data!.twistSlicePrun;
  static List<int> get flipSlicePrun => _data!.flipSlicePrun;
  static List<int> get cpUspPrun => _data!.cpUspPrun;
  static List<int> get epUspPrun => _data!.epUspPrun;

  static final _log = Logger('KociembaTables');
  static bool _initialized = false;
  static bool get initialized => _initialized;

  static Future<void> init() async {
    if (_data != null) return;
    if (_initFuture != null) return _initFuture;

    _log.info('Starting KociembaTables initialization (via isolate)');
    _initFuture = _doInit();
    await _initFuture;
  }

  static Future<void> _doInit() async {
    try {
      final ByteData data =
          await rootBundle.load('assets/kociemba_tables.bin');
      final Uint8List binary = data.buffer.asUint8List();

      // Use compute to run the heavy decoding in a background isolate
      _data = await compute(_decodeTables, binary);
      _log.info('KociembaTables initialized in background');
      _initialized = true;
      _verifyPruning();
    } catch (e, stack) {
      _log.severe('Failed to load asset tables', e, stack);
    }
  }

  static void _verifyPruning() {
    if (_data == null) return;
    int tsUnreachable = twistSlicePrun.where((v) => v == -1).length;
    int fsUnreachable = flipSlicePrun.where((v) => v == -1).length;
    int cuUnreachable = cpUspPrun.where((v) => v == -1).length;
    int euUnreachable = epUspPrun.where((v) => v == -1).length;

    if (tsUnreachable > 0 ||
        fsUnreachable > 0 ||
        cuUnreachable > 0 ||
        euUnreachable > 0) {
      _log.warning(
          'Unreachable states in pruning tables: TS:$tsUnreachable, FS:$fsUnreachable, CU:$cuUnreachable, EU:$euUnreachable');
    } else {
      _log.fine('Pruning tables verify OK.');
    }
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
}

/// Heavy decoding logic moved out of class for compute() compatibility
KociembaTableData _decodeTables(Uint8List binary) {
  final reader = _ByteReader(binary);

  List<List<int>> readMoveTable(int rows, int cols) {
    return List.generate(rows, (_) {
      final row = List.filled(cols, 0);
      for (int j = 0; j < cols; j++) {
        row[j] = reader.readUint16();
      }
      return row;
    });
  }

  List<int> readPruningTable(int size) {
    final list = List.filled(size, 0);
    for (int i = 0; i < size; i++) {
      final val = reader.readUint8();
      list[i] = val == 255 ? -1 : val;
    }
    return list;
  }

  final twistMove = readMoveTable(KociembaTables.nTwist, 18);
  final flipMove = readMoveTable(KociembaTables.nFlip, 18);
  final sliceMove = readMoveTable(KociembaTables.nSlice, 18);
  final cpMove = readMoveTable(KociembaTables.nPerm, 10);
  final epMove = readMoveTable(KociembaTables.nPerm, 10);
  final uspMove = readMoveTable(KociembaTables.nSlicePerm, 10);

  final twistSlicePrun =
      readPruningTable(KociembaTables.nTwist * KociembaTables.nSlice);
  final flipSlicePrun =
      readPruningTable(KociembaTables.nFlip * KociembaTables.nSlice);
  final cpUspPrun =
      readPruningTable(KociembaTables.nPerm * KociembaTables.nSlicePerm);
  final epUspPrun =
      readPruningTable(KociembaTables.nPerm * KociembaTables.nSlicePerm);

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

class _ByteReader {
  final Uint8List data;
  int pos = 0;
  _ByteReader(this.data);

  int readUint8() => data[pos++];
  int readUint16() {
    int val = data[pos] | (data[pos + 1] << 8);
    pos += 2;
    return val;
  }
}
