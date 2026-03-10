import 'cube_move.dart';

/// Categories for algorithm cases
enum AlgCategory { f2l, oll, pll }

/// A single algorithm case (OLL or PLL)
class AlgCase {
  final String id;
  final String name;
  final AlgCategory category;
  final String subcategory;
  final String algorithm; // Standard notation string (U D R L F B only)
  final String setupMoves; // Moves to apply from solved to reach this case
  final String description;
  final bool isFree; // Available without premium

  const AlgCase({
    required this.id,
    required this.name,
    required this.category,
    required this.subcategory,
    required this.algorithm,
    required this.setupMoves,
    required this.description,
    this.isFree = false,
  });

  List<CubeMove> get algorithmMoves => _parseMoves(algorithm);
  List<CubeMove> get setupMoveList => _parseMoves(setupMoves);

  static List<CubeMove> _parseMoves(String notation) {
    if (notation.trim().isEmpty) return [];
    return notation
        .trim()
        .split(RegExp(r'\s+'))
        .map((s) => CubeMove.parse(s))
        .whereType<CubeMove>()
        .toList();
  }
}

/// Static library of all OLL and PLL algorithm cases.
/// All algorithms use only standard face notation: U D R L F B (with ' and 2).
class AlgLibrary {
  static const List<AlgCase> all = [...f2lCases, ...ollCases, ...pllCases];

  static List<AlgCase> get f2l => f2lCases;
  static List<AlgCase> get oll => ollCases;
  static List<AlgCase> get pll => pllCases;

  // ─────────────────────────────────────────────────────────────────────────
  // OLL CASES
  // OLL = Orient Last Layer. The goal is to make the top face all yellow.
  // Each case describes the pattern of yellow stickers visible on top.
  // ─────────────────────────────────────────────────────────────────────────
  static const List<AlgCase> ollCases = [
    // ── Dot ──────────────────────────────────────────────────────────────
    // No edges are oriented — only the center is yellow on top.
    AlgCase(
      id: 'oll1',
      name: 'OLL 1',
      category: AlgCategory.oll,
      subcategory: 'Dot',
      algorithm: "R U2 R2 F R F' U2 R' F R F'",
      setupMoves: "F R' F' R U2 R U2 R2 F' R F",
      description:
          'Dot: no edges oriented. Combines a Sune with an F-move setup. One of the hardest OLL cases — 11 moves.',
      isFree: true,
    ),
    AlgCase(
      id: 'oll2',
      name: 'OLL 2',
      category: AlgCategory.oll,
      subcategory: 'Dot',
      algorithm: "F R U R' U' F' B U R U' R' B'",
      setupMoves: "B R U R' U' B' F R U R' U' F'",
      description:
          'Dot: no edges oriented. Uses two "sexy move" triggers — one on F, one on B. Symmetric and satisfying to execute.',
      isFree: true,
    ),
    AlgCase(
      id: 'oll3',
      name: 'OLL 3',
      category: AlgCategory.oll,
      subcategory: 'Dot',
      algorithm: "B U R U' R' B' U' F R U R' U' F'",
      setupMoves: "F R U R' U' F' U B U R U' R' B'",
      description:
          'Dot: no edges oriented. A B-face trigger followed by a U\' and an F-face trigger. The U\' between them is key.',
      isFree: true,
    ),
    AlgCase(
      id: 'oll4',
      name: 'OLL 4',
      category: AlgCategory.oll,
      subcategory: 'Dot',
      algorithm: "B U R U' R' B' U F R U R' U' F'",
      setupMoves: "F R U R' U' F' U' B U R U' R' B'",
      description:
          'Dot: no edges oriented. Like OLL 3 but with U instead of U\' between the two triggers. Mirror of OLL 3.',
    ),

    // ── Cross ─────────────────────────────────────────────────────────────
    // All 4 edges are oriented — a yellow cross is visible on top.
    // These are the most common OLL cases for beginners.
    AlgCase(
      id: 'oll21',
      name: 'OLL 21',
      category: AlgCategory.oll,
      subcategory: 'Cross',
      algorithm: "R U2 R' U' R U R' U' R U' R'",
      setupMoves: "R U R' U R U' R' U R U2 R'",
      description:
          'Cross: all edges oriented. Called "Anti-Sune" — the reverse of the Sune. All 4 corners are twisted. Very common case.',
    ),
    AlgCase(
      id: 'oll22',
      name: 'OLL 22',
      category: AlgCategory.oll,
      subcategory: 'Cross',
      algorithm: "R U2 R2 U' R2 U' R2 U2 R",
      setupMoves: "R' U2 R2 U R2 U R2 U2 R'",
      description:
          'Cross: all edges oriented. Called "Pi" — two corners point up on opposite sides. Short and efficient at 9 moves.',
    ),
    AlgCase(
      id: 'oll23',
      name: 'OLL 23',
      category: AlgCategory.oll,
      subcategory: 'Cross',
      algorithm: "R2 D' R U2 R' D R U2 R",
      setupMoves: "R' U2 R' D' R U2 R D R2",
      description:
          'Cross: all edges oriented. Called "Headlights" — two adjacent corners face the same direction. Uses a D-move which is unusual for OLL.',
    ),
    AlgCase(
      id: 'oll24',
      name: 'OLL 24',
      category: AlgCategory.oll,
      subcategory: 'Cross',
      algorithm: "L' U' L U L F' L' F",
      setupMoves: "F' L F L' U' L U L'",
      description:
          'Cross: all edges oriented. A left-hand version of a common trigger. Only 8 moves — one of the shorter cross cases.',
    ),
    AlgCase(
      id: 'oll25',
      name: 'OLL 25',
      category: AlgCategory.oll,
      subcategory: 'Cross',
      algorithm: "F' L' U' L U F",
      setupMoves: "F' U' L U L' F",
      description:
          'Cross: all edges oriented. Just 6 moves — the shortest OLL algorithm. A simple F-trigger on the left side.',
    ),
    AlgCase(
      id: 'oll26',
      name: 'OLL 26',
      category: AlgCategory.oll,
      subcategory: 'Cross',
      algorithm: "R U2 R' U' R U' R'",
      setupMoves: "R U R' U R U2 R'",
      description:
          'Cross: all edges oriented. The classic "Sune" — one of the first OLL algorithms beginners learn. Only 7 moves.',
      isFree: true,
    ),
    AlgCase(
      id: 'oll27',
      name: 'OLL 27',
      category: AlgCategory.oll,
      subcategory: 'Cross',
      algorithm: "R U R' U R U2 R'",
      setupMoves: "R U2 R' U' R U' R'",
      description:
          'Cross: all edges oriented. The "Anti-Sune" (right-hand version). Mirror of OLL 26. Also only 7 moves.',
      isFree: true,
    ),

    // ── T-shape ───────────────────────────────────────────────────────────
    // Two adjacent edges oriented, forming a T with the center.
    AlgCase(
      id: 'oll33',
      name: 'OLL 33',
      category: AlgCategory.oll,
      subcategory: 'T-shape',
      algorithm: "R U R' U' R' F R F'",
      setupMoves: "F R' F' R U R U' R'",
      description:
          'T-shape: two adjacent edges oriented. One of the most common OLL cases. The algorithm is a "sexy move" followed by a sledgehammer.',
      isFree: true,
    ),
    AlgCase(
      id: 'oll45',
      name: 'OLL 45',
      category: AlgCategory.oll,
      subcategory: 'T-shape',
      algorithm: "F R U R' U' F'",
      setupMoves: "F U R U' R' F'",
      description:
          'T-shape: two adjacent edges oriented. Just 6 moves — "F sexy F\'". The most beginner-friendly OLL. Often learned first.',
      isFree: true,
    ),

    // ── Square ────────────────────────────────────────────────────────────
    // Two adjacent stickers form a square block in one corner of the top.
    AlgCase(
      id: 'oll5',
      name: 'OLL 5',
      category: AlgCategory.oll,
      subcategory: 'Square',
      algorithm: "L' U2 L U L' U L",
      setupMoves: "L' U' L U' L U2 L'",
      description:
          'Square: a 1×2 block of yellow in the back-left corner. A left-hand Sune variant — only 7 moves.',
    ),
    AlgCase(
      id: 'oll6',
      name: 'OLL 6',
      category: AlgCategory.oll,
      subcategory: 'Square',
      algorithm: "R U2 R' U' R U' R'",
      setupMoves: "R U R' U R U2 R'",
      description:
          'Square: a 1×2 block of yellow in the back-right corner. The right-hand Sune — same as OLL 26. Mirror of OLL 5.',
    ),

    // ── C-shape ───────────────────────────────────────────────────────────
    // Two opposite edges oriented, with corners on one side — looks like a C.
    AlgCase(
      id: 'oll34',
      name: 'OLL 34',
      category: AlgCategory.oll,
      subcategory: 'C-shape',
      algorithm: "R U R2 U' R' F R U R U' F'",
      setupMoves: "F U R' U R F' R U R2 U' R'",
      description:
          'C-shape: two opposite edges oriented. An 11-move algorithm that combines an R-move setup with an F-trigger.',
    ),
    AlgCase(
      id: 'oll46',
      name: 'OLL 46',
      category: AlgCategory.oll,
      subcategory: 'C-shape',
      algorithm: "R' U' R' F R F' U R",
      setupMoves: "R' U' F' R F R U R",
      description:
          'C-shape: two opposite edges oriented. Only 8 moves. Uses an F-trigger in the middle — efficient and elegant.',
    ),

    // ── W-shape ───────────────────────────────────────────────────────────
    // The yellow pattern resembles a W across the top.
    AlgCase(
      id: 'oll36',
      name: 'OLL 36',
      category: AlgCategory.oll,
      subcategory: 'W-shape',
      algorithm: "R U R' F' R U R' U' R' F R2 U' R'",
      setupMoves: "R U R2 F' R U' R U R' F R U' R'",
      description:
          'W-shape: a wide asymmetric yellow pattern. A 13-move algorithm — one of the longer OLL cases. Requires careful finger-tricking.',
    ),
    AlgCase(
      id: 'oll38',
      name: 'OLL 38',
      category: AlgCategory.oll,
      subcategory: 'W-shape',
      algorithm: "R U R' U R U' R' U' R' F R F'",
      setupMoves: "F R' F' R U R U' R' U R U' R'",
      description:
          'W-shape: mirror of OLL 36. An 11-move algorithm ending in a sledgehammer. The U\' U\' in the middle is the key rhythm.',
    ),

    // ── L-shape ───────────────────────────────────────────────────────────
    // Two adjacent edges oriented, with the pattern forming an L.
    AlgCase(
      id: 'oll47',
      name: 'OLL 47',
      category: AlgCategory.oll,
      subcategory: 'L-shape',
      algorithm: "F' L' U' L U L' U' L U F",
      setupMoves: "F' U' L U L' U' L U L' F",
      description:
          'L-shape: two adjacent edges, corners on one side. A left-hand trigger wrapped in F\' … F. 10 moves.',
    ),
    AlgCase(
      id: 'oll48',
      name: 'OLL 48',
      category: AlgCategory.oll,
      subcategory: 'L-shape',
      algorithm: "F R U R' U' R U R' U' F'",
      setupMoves: "F U R U' R' U R U' R' F'",
      description:
          'L-shape: mirror of OLL 47. A double sexy move wrapped in F … F\'. 10 moves.',
    ),
    AlgCase(
      id: 'oll49',
      name: 'OLL 49',
      category: AlgCategory.oll,
      subcategory: 'L-shape',
      algorithm: "R B' R2 F R2 B R2 F' R",
      setupMoves: "R' F R2 B' R2 F' R2 B R'",
      description:
          'L-shape: uses B-face moves which are unusual for OLL. The R2 moves make this recognizable by sound.',
    ),
    AlgCase(
      id: 'oll50',
      name: 'OLL 50',
      category: AlgCategory.oll,
      subcategory: 'L-shape',
      algorithm: "R' F R2 B' R2 F' R2 B R'",
      setupMoves: "R B' R2 F R2 B R2 F' R",
      description:
          'L-shape: mirror of OLL 49. Same B-face structure, reversed. Setup and algorithm are each other\'s inverse.',
    ),
    AlgCase(
      id: 'oll53',
      name: 'OLL 53',
      category: AlgCategory.oll,
      subcategory: 'L-shape',
      algorithm: "L' U' L U' L' U L U' L' U2 L",
      setupMoves: "L' U2 L U' L' U L U' L' U L",
      description:
          'L-shape: a left-hand 11-move algorithm. The repeated L\' U L pattern makes it easy to learn with muscle memory.',
    ),
    AlgCase(
      id: 'oll54',
      name: 'OLL 54',
      category: AlgCategory.oll,
      subcategory: 'L-shape',
      algorithm: "R U R' U R U' R' U R U2 R'",
      setupMoves: "R U2 R' U R U' R' U R U' R'",
      description:
          'L-shape: mirror of OLL 53. A right-hand 11-move algorithm. The U2 at the end is the key distinguishing move.',
    ),

    // ── P-shape ───────────────────────────────────────────────────────────
    // The yellow pattern resembles the letter P.
    AlgCase(
      id: 'oll31',
      name: 'OLL 31',
      category: AlgCategory.oll,
      subcategory: 'P-shape',
      algorithm: "R' U' F U R U' R' F' R",
      setupMoves: "R' F R U R' F' U' R",
      description:
          'P-shape: one edge and two corners oriented. A 9-move algorithm with an F-move in the middle — elegant and efficient.',
    ),
    AlgCase(
      id: 'oll32',
      name: 'OLL 32',
      category: AlgCategory.oll,
      subcategory: 'P-shape',
      algorithm: "R U B' U' R' U R B R'",
      setupMoves: "R' B' R U' R B U R'",
      description:
          'P-shape: mirror of OLL 31. Uses a B-face move instead of F. 9 moves — same length as its mirror.',
    ),
    AlgCase(
      id: 'oll43',
      name: 'OLL 43',
      category: AlgCategory.oll,
      subcategory: 'P-shape',
      algorithm: "R' U' F' U F R",
      setupMoves: "R' F' U' F U R",
      description:
          'P-shape: only 6 moves — one of the shortest OLL algorithms. A simple right-hand trigger with F-moves.',
    ),
    AlgCase(
      id: 'oll44',
      name: 'OLL 44',
      category: AlgCategory.oll,
      subcategory: 'P-shape',
      algorithm: "R U F U' F' R'",
      setupMoves: "R F U F' U' R'",
      description:
          'P-shape: mirror of OLL 43. Also just 6 moves. The F U\' F\' in the middle is a reverse trigger.',
    ),

    // ── S-shape ───────────────────────────────────────────────────────────
    // The yellow pattern resembles an S or Z across the top.
    AlgCase(
      id: 'oll28',
      name: 'OLL 28',
      category: AlgCategory.oll,
      subcategory: 'S-shape',
      algorithm: "L F' L' F U F U' F'",
      setupMoves: "F U F' U' F' L F L'",
      description:
          'S-shape: two opposite edges oriented diagonally. An 8-move algorithm mixing L and F triggers.',
    ),
    AlgCase(
      id: 'oll57',
      name: 'OLL 57',
      category: AlgCategory.oll,
      subcategory: 'S-shape',
      algorithm: "R U R' U' L' U R U' R' L",
      setupMoves: "L' U R U' R' L U R U' R'",
      description:
          'S-shape: uses both R and L moves — unusual for OLL. The L at the end is the key move that orients the last corner.',
    ),

    // ── Z-shape ───────────────────────────────────────────────────────────
    // Two opposite edges oriented, corners on both sides — looks like a Z.
    AlgCase(
      id: 'oll29',
      name: 'OLL 29',
      category: AlgCategory.oll,
      subcategory: 'Z-shape',
      algorithm: "R U R' U' R U' R' F' U' F R U R'",
      setupMoves: "R' U' R F' U F R U R' U R U' R'",
      description:
          'Z-shape: a 13-move algorithm. The F\' U\' F in the middle is a reverse trigger that flips two corners.',
    ),
    AlgCase(
      id: 'oll30',
      name: 'OLL 30',
      category: AlgCategory.oll,
      subcategory: 'Z-shape',
      algorithm: "F U R U2 R' U' R U2 R' U' F'",
      setupMoves: "F U R U2 R' U R U2 R' U' F'",
      description:
          'Z-shape: mirror of OLL 29. An 11-move algorithm. The U2 moves inside the F … F\' wrapper are the key rhythm.',
    ),

    // ── Knight Move ───────────────────────────────────────────────────────
    // The yellow pattern resembles an L-shaped knight move in chess.
    AlgCase(
      id: 'oll13',
      name: 'OLL 13',
      category: AlgCategory.oll,
      subcategory: 'Knight Move',
      algorithm: "F U R U' R2 F' R U R U' R'",
      setupMoves: "R U R' U R F R2 F' U' R U' R'",
      description:
          'Knight Move: an asymmetric pattern with one edge and one corner. The R2 in the middle is the distinguishing move.',
    ),
    AlgCase(
      id: 'oll14',
      name: 'OLL 14',
      category: AlgCategory.oll,
      subcategory: 'Knight Move',
      algorithm: "R' F R U R' F' R F U' F'",
      setupMoves: "F U F' R' F R U' R' F' R",
      description:
          'Knight Move: mirror of OLL 13. Uses alternating R and F triggers. 10 moves.',
    ),
    AlgCase(
      id: 'oll15',
      name: 'OLL 15',
      category: AlgCategory.oll,
      subcategory: 'Knight Move',
      algorithm: "L' U' L U' L' U L U' L' U2 L",
      setupMoves: "L' U2 L U' L' U L U' L' U L",
      description:
          'Knight Move: a left-hand 11-move algorithm. The repeated L\' U L pattern with decreasing U counts is the key.',
    ),
    AlgCase(
      id: 'oll16',
      name: 'OLL 16',
      category: AlgCategory.oll,
      subcategory: 'Knight Move',
      algorithm: "R U R' U R U' R' U R U2 R'",
      setupMoves: "R U2 R' U R U' R' U R U' R'",
      description:
          'Knight Move: mirror of OLL 15. Right-hand version. The U2 at the end distinguishes it from other R-move sequences.',
    ),

    // ── Fish ─────────────────────────────────────────────────────────────
    // The yellow pattern resembles a fish shape on the top layer.
    AlgCase(
      id: 'oll9',
      name: 'OLL 9',
      category: AlgCategory.oll,
      subcategory: 'Fish',
      algorithm: "R U R' U' R' F R2 U R' U' F'",
      setupMoves: "F U R U' R2 F' R U R U' R'",
      description:
          'Fish: one corner and one edge oriented. An 11-move algorithm. The R2 in the middle is the "fish tail" move.',
    ),
    AlgCase(
      id: 'oll10',
      name: 'OLL 10',
      category: AlgCategory.oll,
      subcategory: 'Fish',
      algorithm: "R U R' U R' F R F' R U2 R'",
      setupMoves: "R U2 R' F' R F R U' R' U' R",
      description:
          'Fish: mirror of OLL 9. An 11-move algorithm. The F R F\' in the middle is a sledgehammer variant.',
    ),
    AlgCase(
      id: 'oll35',
      name: 'OLL 35',
      category: AlgCategory.oll,
      subcategory: 'Fish',
      algorithm: "R U2 R2 F R F' R U2 R'",
      setupMoves: "R U2 R' F R' F' R2 U2 R'",
      description:
          'Fish: a symmetric fish case. Only 9 moves. The F R F\' trigger in the middle is sandwiched between R U2 moves.',
    ),
    AlgCase(
      id: 'oll37',
      name: 'OLL 37',
      category: AlgCategory.oll,
      subcategory: 'Fish',
      algorithm: "F R' F' R U R U' R'",
      setupMoves: "R U R' U' R' F R F'",
      description:
          'Fish: only 8 moves. A reverse sledgehammer followed by a sexy move. Very finger-trick friendly.',
    ),

    // ── Lightning ─────────────────────────────────────────────────────────
    // The yellow pattern resembles a lightning bolt across the top.
    AlgCase(
      id: 'oll7',
      name: 'OLL 7',
      category: AlgCategory.oll,
      subcategory: 'Lightning',
      algorithm: "L' U' L U' L' U2 L",
      setupMoves: "L' U2 L U L' U L",
      description:
          'Lightning: only 7 moves — a left-hand Sune. One of the most efficient OLL algorithms. Great for beginners.',
    ),
    AlgCase(
      id: 'oll8',
      name: 'OLL 8',
      category: AlgCategory.oll,
      subcategory: 'Lightning',
      algorithm: "R U R' U R U2 R'",
      setupMoves: "R U2 R' U' R U' R'",
      description:
          'Lightning: the right-hand Sune — same as OLL 26/27. Only 7 moves. Mirror of OLL 7.',
    ),
    AlgCase(
      id: 'oll11',
      name: 'OLL 11',
      category: AlgCategory.oll,
      subcategory: 'Lightning',
      algorithm: "L' U' L U' L' U L U' L' U2 L",
      setupMoves: "L' U2 L U' L' U L U' L' U L",
      description:
          'Lightning: an 11-move left-hand algorithm. The pattern of U\' moves decreasing by one each time makes it rhythmic.',
    ),
    AlgCase(
      id: 'oll12',
      name: 'OLL 12',
      category: AlgCategory.oll,
      subcategory: 'Lightning',
      algorithm: "R U R' U R U' R' U R U2 R'",
      setupMoves: "R U2 R' U R U' R' U R U' R'",
      description:
          'Lightning: mirror of OLL 11. Right-hand 11-move version. The U2 at the end is the key distinguishing move.',
    ),

    // ── Awkward ───────────────────────────────────────────────────────────
    // Cases that don't fit neatly into other shapes — often require longer algorithms.
    AlgCase(
      id: 'oll39',
      name: 'OLL 39',
      category: AlgCategory.oll,
      subcategory: 'Awkward',
      algorithm: "R U R' F' U' F U R U2 R'",
      setupMoves: "R U2 R' U' F' U F R U' R'",
      description:
          'Awkward: a tricky 10-move case. The F\' U\' F in the middle is a reverse trigger. Often confused with similar cases.',
    ),
    AlgCase(
      id: 'oll40',
      name: 'OLL 40',
      category: AlgCategory.oll,
      subcategory: 'Awkward',
      algorithm: "R' F R U R' U' F' U R",
      setupMoves: "R' U' F U R U' R' F' R",
      description:
          'Awkward: mirror of OLL 39. Only 9 moves. The F … F\' wrapper around a sexy move is the key structure.',
    ),
    AlgCase(
      id: 'oll51',
      name: 'OLL 51',
      category: AlgCategory.oll,
      subcategory: 'Awkward',
      algorithm: "B U R U' R' U R U' R' B'",
      setupMoves: "B U R U' R' U R U' R' B'",
      description:
          'Awkward: a double sexy move wrapped in B … B\'. 10 moves. The B-face wrapper is unusual and requires a grip change.',
    ),
    AlgCase(
      id: 'oll52',
      name: 'OLL 52',
      category: AlgCategory.oll,
      subcategory: 'Awkward',
      algorithm: "R U R' U R U' B U' B' R'",
      setupMoves: "R B U B' U' R' U' R U' R'",
      description:
          'Awkward: a 10-move algorithm mixing R and B triggers. The B U\' B\' at the end is a reverse B-trigger.',
    ),
    AlgCase(
      id: 'oll55',
      name: 'OLL 55',
      category: AlgCategory.oll,
      subcategory: 'Awkward',
      algorithm: "R U2 R2 U' R U' R' U2 F R F'",
      setupMoves: "F R' F' U2 R U R' U R2 U2 R'",
      description:
          'Awkward: an 11-move algorithm. The F R F\' sledgehammer at the end is the key — it orients the final corner.',
    ),
    AlgCase(
      id: 'oll56',
      name: 'OLL 56',
      category: AlgCategory.oll,
      subcategory: 'Awkward',
      algorithm: "L' U' L U' L' U L U' L' U2 L U R U' R'",
      setupMoves: "R U R' U' L' U2 L U' L' U L U' L' U L",
      description:
          'Awkward: one of the longest OLL algorithms at 15 moves. Combines a left-hand Sune with a right-hand trigger.',
    ),

    // ── I-shape ───────────────────────────────────────────────────────────
    // Two opposite edges oriented, with a bar of yellow across the middle.
    AlgCase(
      id: 'oll17',
      name: 'OLL 17',
      category: AlgCategory.oll,
      subcategory: 'I-shape',
      algorithm: "R U R' U R' F R F' U2 R' F R F'",
      setupMoves: "F R' F' R U2 F R' F' R U' R U' R'",
      description:
          'I-shape: two opposite edges oriented, corners on both sides. A 13-move algorithm with two F-triggers.',
    ),
    AlgCase(
      id: 'oll18',
      name: 'OLL 18',
      category: AlgCategory.oll,
      subcategory: 'I-shape',
      algorithm: "L' U' L U' L' U2 L U R U' R' U R U2 R'",
      setupMoves: "R U2 R' U R U' R' U' L' U2 L U L' U L",
      description:
          'I-shape: a 15-move algorithm combining left and right Sune variants. One of the most complex OLL cases.',
    ),
    AlgCase(
      id: 'oll19',
      name: 'OLL 19',
      category: AlgCategory.oll,
      subcategory: 'I-shape',
      algorithm: "L' U' L U' L' U L U F' L' F L",
      setupMoves: "L' F' L F U' L' U L U' L' U L",
      description:
          'I-shape: a 12-move algorithm. The F\' L\' F L at the end is a left-hand sledgehammer that orients the last piece.',
    ),
    AlgCase(
      id: 'oll20',
      name: 'OLL 20',
      category: AlgCategory.oll,
      subcategory: 'I-shape',
      algorithm: "R U R' U' L' U R U' R' L",
      setupMoves: "L' U R U' R' L U R U' R'",
      description:
          'I-shape: only 10 moves. Uses both R and L moves. The L at the end is the key move that completes the orientation.',
    ),

    // ── Corners Only ──────────────────────────────────────────────────────
    // All 4 edges are already oriented — only corners need to be fixed.
    AlgCase(
      id: 'oll41',
      name: 'OLL 41',
      category: AlgCategory.oll,
      subcategory: 'Corners Only',
      algorithm: "R U' R' U2 R U R' U2 R U' R' U R U' R'",
      setupMoves: "R U R' U' R U R' U2 R U' R' U2 R U R'",
      description:
          'Corners Only: all edges oriented, 2 corners twisted. A 15-move algorithm — the longest standard OLL. Requires patience.',
    ),
    AlgCase(
      id: 'oll42',
      name: 'OLL 42',
      category: AlgCategory.oll,
      subcategory: 'Corners Only',
      algorithm: "R U R' U R U' R' U' R' F R F'",
      setupMoves: "F R' F' R U R U' R' U R U' R'",
      description:
          'Corners Only: all edges oriented, 2 corners twisted. An 11-move algorithm ending in a sledgehammer.',
    ),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // PLL CASES (21 total)
  // PLL = Permute Last Layer. The top is all yellow — now pieces need to
  // move to their correct positions without disturbing orientation.
  // ─────────────────────────────────────────────────────────────────────────
  static const List<AlgCase> pllCases = [
    // ── Corners Only ──────────────────────────────────────────────────────
    // Only the 4 corners need to be permuted; edges are already solved.
    AlgCase(
      id: 'pll_aa',
      name: 'Aa-perm',
      category: AlgCategory.pll,
      subcategory: 'Corners Only',
      algorithm: "R' F R' B2 R F' R' B2 R2",
      setupMoves: "R2 B2 R F R' B2 R F' R",
      description:
          'Corners Only: 3-cycle of corners (CCW). One corner stays fixed while the other three rotate counter-clockwise.',
      isFree: true,
    ),
    AlgCase(
      id: 'pll_ab',
      name: 'Ab-perm',
      category: AlgCategory.pll,
      subcategory: 'Corners Only',
      algorithm: "R2 B2 R F R' B2 R F' R",
      setupMoves: "R' F R' B2 R F' R' B2 R2",
      description:
          'Corners Only: 3-cycle of corners (CW). Mirror of Aa-perm. One corner stays fixed while the other three rotate clockwise.',
      isFree: true,
    ),
    AlgCase(
      id: 'pll_e',
      name: 'E-perm',
      category: AlgCategory.pll,
      subcategory: 'Corners Only',
      algorithm: "R B' R' F R B R' F' R B R' F R B' R' F'",
      setupMoves: "F R B' R' F' R B R' F R B' R' F' R B R'",
      description:
          'Corners Only: diagonal swap of all 4 corners. No corner stays in place. A 16-move algorithm — one of the hardest PLLs.',
    ),

    // ── Edges Only ────────────────────────────────────────────────────────
    // Only the 4 edges need to be permuted; corners are already solved.
    AlgCase(
      id: 'pll_ua',
      name: 'Ua-perm',
      category: AlgCategory.pll,
      subcategory: 'Edges Only',
      algorithm: "R U' R U R U R U' R' U' R2",
      setupMoves: "R2 U R U R' U' R' U' R' U R'",
      description:
          'Edges Only: 3-cycle of edges (CCW). One edge stays fixed while the other three rotate counter-clockwise. Very common.',
      isFree: true,
    ),
    AlgCase(
      id: 'pll_ub',
      name: 'Ub-perm',
      category: AlgCategory.pll,
      subcategory: 'Edges Only',
      algorithm: "R2 U' R' U' R U R U R U' R",
      setupMoves: "R' U R' U' R' U' R' U R U R2",
      description:
          'Edges Only: 3-cycle of edges (CW). Mirror of Ua-perm. One edge stays fixed while the other three rotate clockwise.',
      isFree: true,
    ),
    AlgCase(
      id: 'pll_z',
      name: 'Z-perm',
      category: AlgCategory.pll,
      subcategory: 'Edges Only',
      algorithm: "R' U' R U' R U R U' R' U R U R2 U' R'",
      setupMoves: "R U R2 U R U' R' U' R U' R' U' R U R'",
      description:
          'Edges Only: swap two pairs of opposite edges. No corners move. A 14-move algorithm — recognizable by its symmetric pattern.',
    ),
    AlgCase(
      id: 'pll_h',
      name: 'H-perm',
      category: AlgCategory.pll,
      subcategory: 'Edges Only',
      algorithm: "R2 U2 R U2 R2 U2 R2 U2 R U2 R2",
      setupMoves: "R2 U2 R' U2 R2 U2 R2 U2 R' U2 R2",
      description:
          'Edges Only: swap all 4 edges in two pairs. Fully symmetric — looks the same from all 4 sides. 11 moves.',
    ),

    // ── Adjacent Corner Swap ──────────────────────────────────────────────
    // Two adjacent corners swap, plus some edges move.
    AlgCase(
      id: 'pll_ja',
      name: 'Ja-perm',
      category: AlgCategory.pll,
      subcategory: 'Adjacent Corner Swap',
      algorithm: "L' U' L F L' U' L U L F' L2 U L",
      setupMoves: "L' U' L2 F L' U L U' L' F' L U L'",
      description:
          'Adjacent Corner Swap: two adjacent corners swap, plus two edges cycle. A 13-move left-hand algorithm.',
    ),
    AlgCase(
      id: 'pll_jb',
      name: 'Jb-perm',
      category: AlgCategory.pll,
      subcategory: 'Adjacent Corner Swap',
      algorithm: "R U R' F' R U R' U' R' F R2 U' R'",
      setupMoves: "R U R2 F' R U R U' R' F R U' R'",
      description:
          'Adjacent Corner Swap: mirror of Ja-perm. Two adjacent corners swap, plus two edges cycle. A 13-move right-hand algorithm.',
    ),
    AlgCase(
      id: 'pll_t',
      name: 'T-perm',
      category: AlgCategory.pll,
      subcategory: 'Adjacent Corner Swap',
      algorithm: "R U R' U' R' F R2 U' R' U' R U R' F'",
      setupMoves: "F R' F' R U R U' R' U R U' R' F R F'",
      description:
          'Adjacent Corner Swap: two adjacent corners swap AND two adjacent edges swap. One of the most common PLLs. 14 moves.',
      isFree: true,
    ),
    AlgCase(
      id: 'pll_f',
      name: 'F-perm',
      category: AlgCategory.pll,
      subcategory: 'Adjacent Corner Swap',
      algorithm: "R' U' F' R U R' U' R' F R2 U' R' U' R U R' U R",
      setupMoves: "R' U' R U' R U R2 F' R2 U R U R' F R U R'",
      description:
          'Adjacent Corner Swap: two adjacent corners swap, plus a 3-cycle of edges. One of the longest PLL algorithms at 18 moves.',
    ),

    // ── Diagonal Corner Swap ──────────────────────────────────────────────
    // Two diagonally opposite corners swap.
    AlgCase(
      id: 'pll_y',
      name: 'Y-perm',
      category: AlgCategory.pll,
      subcategory: 'Diagonal Corner Swap',
      algorithm: "F R U' R' U' R U R' F' R U R' U' R' F R F'",
      setupMoves: "F R' F' R U R U' R' F R U' R' U' R U R' F'",
      description:
          'Diagonal Corner Swap: two diagonally opposite corners swap, plus two edges cycle. A 17-move algorithm. Very common.',
    ),
    AlgCase(
      id: 'pll_v',
      name: 'V-perm',
      category: AlgCategory.pll,
      subcategory: 'Diagonal Corner Swap',
      algorithm: "R' U R' U' B' R' B2 U' B' U B' R B R",
      setupMoves: "R' B' R B' U B R2 B' R U' R U R'",
      description:
          'Diagonal Corner Swap: two diagonally opposite corners swap, plus two edges swap. A 14-move algorithm.',
    ),

    // ── G-perms ───────────────────────────────────────────────────────────
    // 4-cycle of corners + 3-cycle of edges. Named Ga, Gb, Gc, Gd.
    AlgCase(
      id: 'pll_ga',
      name: 'Ga-perm',
      category: AlgCategory.pll,
      subcategory: 'G-perms',
      algorithm: "R2 U R' U R' U' R U' R2 D U' R' U R D'",
      setupMoves: "D R' U' R U D' R2 U R' U' R U R' U' R2",
      description:
          'G-perm: 4-cycle of corners + 3-cycle of edges. Uses a D-move — unusual for PLL. One of 4 related G-perm cases.',
    ),
    AlgCase(
      id: 'pll_gb',
      name: 'Gb-perm',
      category: AlgCategory.pll,
      subcategory: 'G-perms',
      algorithm: "R' U' R U D' R2 U R' U R U' R U' R2 D",
      setupMoves: "D' R2 U R' U R U' R U R2 D U R U' R'",
      description:
          'G-perm: 4-cycle of corners + 3-cycle of edges (reverse direction). Mirror of Ga-perm in terms of corner cycle.',
    ),
    AlgCase(
      id: 'pll_gc',
      name: 'Gc-perm',
      category: AlgCategory.pll,
      subcategory: 'G-perms',
      algorithm: "R2 U' R U' R U R' U R2 D' U R U' R' D",
      setupMoves: "D R' U R' U' R2 U' R U' R U R2 D' U' R2",
      description:
          'G-perm: 4-cycle of corners + 3-cycle of edges. Inverse of Ga-perm. The D\' instead of D is the key difference.',
    ),
    AlgCase(
      id: 'pll_gd',
      name: 'Gd-perm',
      category: AlgCategory.pll,
      subcategory: 'G-perms',
      algorithm: "R U R' U' D R2 U' R U' R' U R' U R2 D'",
      setupMoves: "D' R2 U' R U R' U R U R2 D U' R' U R",
      description:
          'G-perm: 4-cycle of corners + 3-cycle of edges. Inverse of Gb-perm. The 4 G-perms are all related by rotation.',
    ),

    // ── R-perms ───────────────────────────────────────────────────────────
    // 3-cycle of corners + 3-cycle of edges on the right side.
    AlgCase(
      id: 'pll_ra',
      name: 'Ra-perm',
      category: AlgCategory.pll,
      subcategory: 'R-perms',
      algorithm: "R U' R' U' R U R D R' U' R D' R' U2 R'",
      setupMoves: "R U2 R' D R U R' D' R U R' U R U' R'",
      description:
          'R-perm: 3-cycle of corners + 3-cycle of edges. The D-move in the middle is the key. One of two R-perm cases.',
    ),
    AlgCase(
      id: 'pll_rb',
      name: 'Rb-perm',
      category: AlgCategory.pll,
      subcategory: 'R-perms',
      algorithm: "R' U2 R U2 R' F R U R' U' R' F' R2 U'",
      setupMoves: "U R2 F R F' R U2 R' U2 R U' R' F R F'",
      description:
          'R-perm: mirror of Ra-perm. 3-cycle of corners + 3-cycle of edges in the opposite direction.',
    ),

    // ── N-perms ───────────────────────────────────────────────────────────
    // Double swap of non-adjacent pieces — the hardest PLL cases.
    AlgCase(
      id: 'pll_na',
      name: 'Na-perm',
      category: AlgCategory.pll,
      subcategory: 'N-perms',
      algorithm: "R U R' U R U R' F' R U R' U' R' F R2 U' R' U2 R U' R'",
      setupMoves: "R U R' U2 R U R2 F' R U R' U' R' F R U' R' U' R U' R'",
      description:
          'N-perm: double diagonal swap of both corners AND edges. No piece stays in place. One of the longest PLLs at 22 moves.',
    ),
    AlgCase(
      id: 'pll_nb',
      name: 'Nb-perm',
      category: AlgCategory.pll,
      subcategory: 'N-perms',
      algorithm: "R' U R U' R' F' U' F R U R' F R' F' R U' R",
      setupMoves: "R' U R F' R U' R' F U R' U' R U R' U R",
      description:
          'N-perm: mirror of Na-perm. Double diagonal swap of corners and edges. Also one of the longest PLLs.',
    ),
  ];

  static const List<AlgCase> f2lCases = [
    AlgCase(
      id: 'f2l1',
      name: 'F2L 1',
      category: AlgCategory.f2l,
      subcategory: 'Basic Insert',
      algorithm: "U R U' R'",
      setupMoves: "R U R' U'",
      description:
          'The most basic F2L insertion. Pair the corner and edge in the top layer and insert into the front-right slot.',
      isFree: true,
    ),
    AlgCase(
      id: 'f2l2',
      name: 'F2L 2',
      category: AlgCategory.f2l,
      subcategory: 'Basic Insert',
      algorithm: "U' L' U L",
      setupMoves: "L' U' L U",
      description:
          'Left-hand version of the basic F2L insertion. Inserts into the front-left slot.',
      isFree: true,
    ),
    AlgCase(
      id: 'f2l3',
      name: 'F2L 3',
      category: AlgCategory.f2l,
      subcategory: 'Connected Pair',
      algorithm: "R U R'",
      setupMoves: "R' U' R",
      description: 'Inserting a pre-formed pair into the front-right slot.',
      isFree: true,
    ),
    AlgCase(
      id: 'f2l4',
      name: 'F2L 4',
      category: AlgCategory.f2l,
      subcategory: 'Split Pair',
      algorithm: "R U' R' U2 R U R'",
      setupMoves: "R U' R' U2 R U R'",
      description: 'Positioning and inserting a split corner/edge pair.',
    ),
  ];
}
