import 'package:flutter/material.dart';
import '../utils/haptic_service.dart';
import '../utils/premium_manager.dart';

class ScrambleSettingsPanel extends StatelessWidget {
  final int scrambleLength;
  final Function(int) onLengthChanged;
  final VoidCallback onScramble;
  final VoidCallback onRandomize;
  final bool isScrambling;
  final bool isAnimating;

  const ScrambleSettingsPanel({
    super.key,
    required this.scrambleLength,
    required this.onLengthChanged,
    required this.onScramble,
    required this.onRandomize,
    required this.isScrambling,
    required this.isAnimating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF818CF8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shuffle,
                    color: Color(0xFF818CF8), size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Scramble",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "$scrambleLength moves",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Premium indicator if needed
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: const Color(0xFF818CF8),
              inactiveTrackColor: Colors.white10,
              thumbColor: const Color(0xFF818CF8),
              // Different color for premium range if not premium
              secondaryActiveTrackColor: !PremiumManager().isPremium
                  ? Colors.amber.withValues(alpha: 0.3)
                  : null,
            ),
            child: Slider(
              value: scrambleLength.toDouble(),
              min: 5,
              max: 20,
              divisions: 15,
              onChanged: (val) {
                final int newLength = val.round();
                HapticService.selection();
                onLengthChanged(newLength);
              },
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: (isScrambling || isAnimating) ? null : onScramble,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    elevation: 0,
                  ),
                  child: isScrambling
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          "SCRAMBLE",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (isScrambling || isAnimating) ? null : onRandomize,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!PremiumManager().isPremium) ...[
                        const Icon(Icons.lock, size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                      ],
                      const Text(
                        "RANDOMIZE",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
