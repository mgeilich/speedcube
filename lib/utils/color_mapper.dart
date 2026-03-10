import '../models/cube_state.dart';
import 'dart:math';

class ColorMapper {
  /// Convert RGB (0-255) to HSV
  /// Returns [hue (0-360), saturation (0-1), value (0-1)]
  static List<double> rgbToHsv(int r, int g, int b) {
    final rNorm = r / 255.0;
    final gNorm = g / 255.0;
    final bNorm = b / 255.0;

    final double maxC = max(max(rNorm, gNorm), bNorm).toDouble();
    final double minC = min(min(rNorm, gNorm), bNorm).toDouble();
    final delta = maxC - minC;

    // Hue calculation
    double hue = 0;
    if (delta != 0) {
      if (maxC == rNorm) {
        hue = 60 * (((gNorm - bNorm) / delta) % 6);
      } else if (maxC == gNorm) {
        hue = 60 * (((bNorm - rNorm) / delta) + 2);
      } else {
        hue = 60 * (((rNorm - gNorm) / delta) + 4);
      }
    }
    if (hue < 0) hue += 360;

    // Saturation
    final double saturation = maxC == 0 ? 0.0 : delta / maxC;

    // Value (brightness)
    final double value = maxC;

    return <double>[hue, saturation, value];
  }

  static CubeColor mapRGB(int r, int g, int b) {
    final hsv = rgbToHsv(r, g, b);
    final hue = hsv[0];
    final saturation = hsv[1];
    final value = hsv[2];

    // White detection:
    // 1. Very low saturation is always white.
    // 2. High brightness (warm lights) can have surprisingly high saturation.
    if (saturation < 0.20 || (value > 0.80 && saturation < 0.48)) {
      return CubeColor.white;
    }

    // Red: 0-12 or 345-360
    if (hue >= 345 || hue < 12) {
      return CubeColor.red;
    }
    // Orange: 12-45
    else if (hue >= 12 && hue < 45) {
      return CubeColor.orange;
    }
    // Yellow: 45-95
    else if (hue >= 45 && hue < 95) {
      return CubeColor.yellow;
    }
    // Green: 95-160
    else if (hue >= 95 && hue < 160) {
      return CubeColor.green;
    }
    // Blue: 210-270 (cyan to blue)
    else if (hue >= 210 && hue < 270) {
      return CubeColor.blue;
    }
    // Default fallback
    else {
      // Hues 150-210 are cyan/teal, 270-330 are purple/magenta
      // Map based on proximity
      if (hue >= 150 && hue < 180) {
        return CubeColor.green; // Teal is closer to green
      } else if (hue >= 180 && hue < 210) {
        return CubeColor.blue; // Cyan is closer to blue
      } else {
        return CubeColor.red; // Purple/magenta closer to red
      }
    }
  }
}
