import 'cube_move.dart';

class FingerTrick {
  final String id;
  final String name;
  final String algorithm;
  final String description;
  final String? videoPath;
  final List<String>? stepExplanations;

  const FingerTrick({
    required this.id,
    required this.name,
    required this.algorithm,
    required this.description,
    this.videoPath,
    this.stepExplanations,
  });

  List<CubeMove> get moves {
    if (algorithm.trim().isEmpty) return [];
    return algorithm
        .trim()
        .split(RegExp(r'\s+'))
        .map((s) => CubeMove.parse(s))
        .whereType<CubeMove>()
        .toList();
  }
}
