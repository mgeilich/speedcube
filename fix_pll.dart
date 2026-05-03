import 'dart:io';

String getInverse(String alg) {
  var moves = alg.trim().split(RegExp(r'\s+'));
  var inv = <String>[];
  for (var m in moves.reversed) {
    if (m.endsWith("'")) {
      inv.add(m.substring(0, m.length - 1));
    } else if (m.endsWith("2")) {
      inv.add(m);
    } else {
      inv.add(m + "'");
    }
  }
  return inv.join(' ');
}

void main() {
  var file = File('lib/models/alg_library.dart');
  var lines = file.readAsLinesSync();
  
  bool inPll = false;
  String currentAlg = '';
  
  for (int i = 0; i < lines.length; i++) {
    var line = lines[i];
    
    if (line.contains('static const List<AlgCase> pllCases = [')) {
      inPll = true;
    }
    if (inPll && line.contains('static const List<AlgCase> f2lCases = [')) {
      inPll = false;
    }
    
    if (inPll) {
      if (line.contains('algorithm: "')) {
        var start = line.indexOf('algorithm: "') + 12;
        var end = line.indexOf('"', start);
        currentAlg = line.substring(start, end);
      }
      if (line.contains('setupMoves: "')) {
        var start = line.indexOf('setupMoves: "') + 13;
        var end = line.indexOf('"', start);
        var expectedSetup = getInverse(currentAlg);
        
        // replace line
        lines[i] = line.substring(0, start) + expectedSetup + line.substring(end);
      }
    }
  }
  
  file.writeAsStringSync(lines.join('\n') + '\n');
  print('Fixed alg_library.dart');
}
