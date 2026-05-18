import 'finger_trick.dart';

class TriggerLibrary {
  static const List<FingerTrick> all = [
    sexyMove,
    sune,
    antiSune,
    sledgehammer,
    hedgeslammer,
    leftySexy,
    leftySledge,
    tTrigger,
  ];

  static const FingerTrick sexyMove = FingerTrick(
    id: 'sexy_move',
    name: 'Sexy Move',
    algorithm: "R U R' U'",
    description: 'The most fundamental trigger in speedcubing. Used in F2L, OLL, and PLL.',
    stepExplanations: [
      'R: Right hand wrist turn upward.',
      'U: Right index finger flick across the top.',
      'R\': Right hand wrist turn downward.',
      'U\': Left index finger flick across the top.',
    ],
  );

  static const FingerTrick sune = FingerTrick(
    id: 'sune',
    name: 'Sune',
    algorithm: "R U R' U R U2 R'",
    description: 'A classic OLL algorithm that rotates three corners. Very fast and rhythmic.',
    stepExplanations: [
      'R U R\': Standard setup.',
      'U: Right index flick.',
      'R U2 R\': Final insertion with a double flick.',
    ],
  );

  static const FingerTrick antiSune = FingerTrick(
    id: 'anti_sune',
    name: 'Anti-Sune',
    algorithm: "R U2 R' U' R U' R'",
    description: 'The inverse of the Sune. Used for the mirror OLL case.',
    stepExplanations: [
      'R U2 R\': Double flick setup.',
      'U\': Left index flick.',
      'R U\' R\': Final insertion.',
    ],
  );

  static const FingerTrick sledgehammer = FingerTrick(
    id: 'sledgehammer',
    name: 'Sledgehammer',
    algorithm: "R' F R F'",
    description: 'A powerful tool for orienting edges and inserting F2L pairs. It replaces a corner and an edge.',
    stepExplanations: [
      'R\': Pull down with right thumb.',
      'F: Push down with right index finger.',
      'R: Push up with right thumb.',
      'F\': Pull up with left index finger.',
    ],
  );

  static const FingerTrick hedgeslammer = FingerTrick(
    id: 'hedgeslammer',
    name: 'Hedgeslammer',
    algorithm: "F R' F' R",
    description: 'The mirror/inverse of the Sledgehammer.',
    stepExplanations: [
      'F: Push down with right index finger.',
      'R\': Pull down with right thumb.',
      'F\': Pull up with left index finger.',
      'R: Push up with right thumb.',
    ],
  );

  static const FingerTrick leftySexy = FingerTrick(
    id: 'lefty_sexy',
    name: 'Lefty Sexy Move',
    algorithm: "L' U' L U",
    description: 'The left-hand mirror of the Sexy Move.',
    stepExplanations: [
      'L\': Left hand wrist turn upward.',
      'U\': Left index finger flick.',
      'L: Left hand wrist turn downward.',
      'U: Right index finger flick.',
    ],
  );

  static const FingerTrick leftySledge = FingerTrick(
    id: 'lefty_sledge',
    name: 'Lefty Sledgehammer',
    algorithm: "L F' L' F",
    description: 'Left-hand version of the Sledgehammer.',
    stepExplanations: [
      'L: Pull down with left thumb.',
      'F\': Push down with left index finger.',
      'L\': Push up with left thumb.',
      'F: Pull up with right index finger.',
    ],
  );

  static const FingerTrick tTrigger = FingerTrick(
    id: 't_trigger',
    name: 'T-Perm Trigger',
    algorithm: "R U R' U'",
    description: 'The first half of a T-Perm, often used in isolation as a pairing trigger.',
    stepExplanations: [
      'R U: Fast wrist and index combo.',
      'R\' U\': Fast return.',
    ],
  );
}
