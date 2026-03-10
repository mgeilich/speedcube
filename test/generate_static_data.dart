// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:speedcube_ar/solver/kociemba_tables_generator.dart';

void main() async {
  print('Generating tables (this may take a minute)...');
  final tables = KociembaTablesGenerator.generateData();

  final buffer = BytesBuilder();

  // Helper to write List<int> (uint8)
  void write1D(List<int> table) {
    for (var val in table) {
      buffer.addByte(val == -1 ? 255 : val);
    }
  }

  // Helper to write List<List<int>> (uint16)
  void writeMoveTable(List<List<int>> table) {
    for (var row in table) {
      for (var val in row) {
        buffer.addByte(val & 0xFF);
        buffer.addByte((val >> 8) & 0xFF);
      }
    }
  }

  writeMoveTable(tables.twistMove);
  print('  Wrote twistMove, buffer len: ${buffer.length}');
  writeMoveTable(tables.flipMove);
  print('  Wrote flipMove, buffer len: ${buffer.length}');
  writeMoveTable(tables.sliceMove);
  print('  Wrote sliceMove, buffer len: ${buffer.length}');
  writeMoveTable(tables.cpMove);
  print('  Wrote cpMove, buffer len: ${buffer.length}');
  writeMoveTable(tables.epMove);
  print('  Wrote epMove, buffer len: ${buffer.length}');
  writeMoveTable(tables.uspMove);
  print('  Wrote uspMove, buffer len: ${buffer.length}');

  write1D(tables.twistSlicePrun);
  print('  Wrote twistSlicePrun, buffer len: ${buffer.length}');
  write1D(tables.flipSlicePrun);
  print('  Wrote flipSlicePrun, buffer len: ${buffer.length}');
  write1D(tables.cpUspPrun);
  print('  Wrote cpUspPrun, buffer len: ${buffer.length}');
  write1D(tables.epUspPrun);
  print('  Wrote epUspPrun, buffer len: ${buffer.length}');

  final data = buffer.takeBytes();
  final b64 = base64Encode(data);

  final outFile = File('lib/solver/kociemba_tables_data.dart');
  outFile.writeAsStringSync('''// THIS FILE IS GENERATED. DO NOT EDIT.
const String KOCIEMBA_TABLES_BASE64 = '$b64';
''');

  print('Done! Saved to \${outFile.path} (\${data.length} bytes raw)');
}
