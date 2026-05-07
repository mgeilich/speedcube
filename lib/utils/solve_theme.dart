import 'package:flutter/material.dart';

class SolveTheme {
  static const Color primaryIndigo = Color(0xFF818CF8);
  static const Color secondaryBlue = Color(0xFF60A5FA);
  static const Color yellowGold = Color(0xFFFACC15);
  static const Color amber = Color(0xFFF59E0B);
  static const Color checkGreen = Color(0xFF10B981);

  static Color getStageColor(String? stageName) {
    if (stageName == null) {
      // Kociemba Phases (Indigo/Purple blend)
      return primaryIndigo;
    }

    final s = stageName.toLowerCase();
    if (s.contains('cross') ||
        s.contains('white layer') ||
        s.contains('white cross') ||
        s.contains('start')) {
      return Colors.white;
    } else if (s.contains('first layer') || s.contains('orientation')) {
      return const Color(0xFF38BDF8); // sky blue
    } else if (s.contains('second layer') ||
        s.contains('middle layer') ||
        s.contains('f2l') ||
        s.contains('block')) {
      return secondaryBlue;
    } else if (s.contains('yellow cross') ||
        s.contains('yellow edges') ||
        s.contains('oll') ||
        s.contains('eoline')) {
      return yellowGold;
    } else if (s.contains('yellow corners') ||
        s.contains('pll') ||
        s.contains('last layer') ||
        s.contains('align')) {
      return amber;
    } else if (s.contains('edge orientation')) {
      return yellowGold;
    } else if (s.contains('commutator')) {
      return const Color(0xFF34D399); // emerald
    } else if (s.contains('final')) {
      return checkGreen;
    }

    return primaryIndigo;
  }
}
