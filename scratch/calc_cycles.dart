import 'package:logging/logging.dart';

// Calculation script for cube cycles

// Indices for a face:
// 0 1 2
// 3 4 5
// 6 7 8

void main() {
  // Configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(record.message);
  });
  final logger = Logger('CalcCycles');

  logger.info('--- Calculating Correct Cycles ---');
  
  _printFaceCycles(logger, 'U', [
    _edge('F', [0, 1, 2]),
    _edge('L', [0, 1, 2]),
    _edge('B', [0, 1, 2]),
    _edge('R', [0, 1, 2]),
  ]);
  
  _printFaceCycles(logger, 'D', [
    _edge('F', [6, 7, 8]),
    _edge('R', [6, 7, 8]),
    _edge('B', [6, 7, 8]),
    _edge('L', [6, 7, 8]),
  ]);
  
  _printFaceCycles(logger, 'F', [
    _edge('U', [6, 7, 8]),
    _edge('R', [0, 3, 6]),
    _edge('D', [2, 1, 0]),
    _edge('L', [8, 5, 2]),
  ]);

  _printFaceCycles(logger, 'B', [
    _edge('U', [2, 1, 0]),
    _edge('L', [0, 3, 6]),
    _edge('D', [6, 7, 8]),
    _edge('R', [8, 5, 2]),
  ]);

  _printFaceCycles(logger, 'R', [
    _edge('U', [2, 5, 8]),
    _edge('B', [6, 3, 0]),
    _edge('D', [2, 5, 8]),
    _edge('F', [2, 5, 8]),
  ]);

  _printFaceCycles(logger, 'L', [
    _edge('U', [0, 3, 6]),
    _edge('F', [0, 3, 6]),
    _edge('D', [0, 3, 6]),
    _edge('B', [8, 5, 2]),
  ]);
}

class Edge {
  final String face;
  final List<int> indices;
  Edge(this.face, this.indices);
}

Edge _edge(String f, List<int> i) => Edge(f, i);

void _printFaceCycles(Logger logger, String name, List<Edge> edges) {
  logger.info('Face $name:');
  final faceOffset = _getOffset(name);
  logger.info('  Face: [${faceOffset+0}, ${faceOffset+2}, ${faceOffset+8}, ${faceOffset+6}], [${faceOffset+1}, ${faceOffset+5}, ${faceOffset+7}, ${faceOffset+3}]');
  
  List<int> c1 = [];
  List<int> c2 = [];
  List<int> c3 = [];
  
  for (int i = 0; i < 4; i++) {
    final offset = _getOffset(edges[i].face);
    c1.add(offset + edges[i].indices[0]);
    c2.add(offset + edges[i].indices[1]);
    c3.add(offset + edges[i].indices[2]);
  }
  
  logger.info('  Sides: $c1, $c2, $c3');
}

int _getOffset(String face) {
  switch (face) {
    case 'U': return 0;
    case 'R': return 9;
    case 'F': return 18;
    case 'D': return 27;
    case 'L': return 36;
    case 'B': return 45;
    default: return 0;
  }
}
