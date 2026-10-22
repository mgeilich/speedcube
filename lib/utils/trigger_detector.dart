import '../models/cube_move.dart';

class TriggerMatch {
  final String name;
  final List<int> moveIndices;
  final bool isTrigger;

  TriggerMatch({
    required this.name,
    required this.moveIndices,
    this.isTrigger = true,
  });
}

class TriggerDetector {
  static const Map<String, List<String>> _triggers = {
    'Sexy': ['R', 'U', "R'", "U'"],
    'L-Sexy': ['L', 'U', "L'", "U'"],
    'Sledge': ["R'", 'F', 'R', "F'"],
    'Hedge': ['F', "R'", "F'", 'R'],
    'U-Trigger': ['R', 'U', "R'"],
    'Hammer': ["R'", 'F', 'R'],
    'F-Trigger': ['F', 'R', 'U', "R'", "U'", "F'"],
  };

  static List<TriggerMatch> detect(List<CubeMove> moves) {
    final results = <TriggerMatch>[];
    final notation = moves.map((m) => m.toString()).toList();
    final used = List.filled(moves.length, false);

    // 1. Try to find complete triggers (longest first)
    // For now, we'll just do simple greedy matching
    int i = 0;
    while (i < moves.length) {
      if (used[i]) {
        i++;
        continue;
      }

      TriggerMatch? bestMatch;
      
      // Check each trigger pattern
      for (final entry in _triggers.entries) {
        final pattern = entry.value;
        if (i + pattern.length <= moves.length) {
          bool match = true;
          for (int j = 0; j < pattern.length; j++) {
            if (notation[i + j] != pattern[j]) {
              match = false;
              break;
            }
          }
          
          if (match) {
            bestMatch = TriggerMatch(
              name: entry.key,
              moveIndices: List.generate(pattern.length, (j) => i + j),
            );
            break;
          }
        }
      }

      if (bestMatch != null) {
        results.add(bestMatch);
        for (final idx in bestMatch.moveIndices) {
          used[idx] = true;
        }
        i += bestMatch.moveIndices.length;
      } else {
        // No trigger found, add as single move
        results.add(TriggerMatch(
          name: notation[i],
          moveIndices: [i],
          isTrigger: false,
        ));
        used[i] = true;
        i++;
      }
    }

    return results;
  }
}
