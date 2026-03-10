import 'package:flutter/services.dart';

class HapticService {
  static Future<void> impactLight() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> impactMedium() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }
}
