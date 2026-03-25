import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/premium_manager.dart';
import 'premium_upsell_sheet.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onScanPressed;
  final VoidCallback onLearnPressed;
  final VoidCallback onSettingsPressed;

  const HomeHeader({
    super.key,
    required this.onScanPressed,
    required this.onLearnPressed,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isShort = MediaQuery.of(context).size.height < 750;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: isShort ? 8 : 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.view_in_ar, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          const Text(
            "SpeedCube AR",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Scan button
              Stack(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.camera_alt,
                        color: Colors.white70, size: 24),
                    onPressed: () {
                      if (!kIsWeb && !PremiumManager().isPremium) {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (context) => const PremiumUpsellSheet(),
                        );
                        return;
                      }
                      onScanPressed();
                    },
                    tooltip: 'Scan Cube',
                  ),
                  if (!kIsWeb && !PremiumManager().isPremium)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F0F1A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: Color(0xFFF59E0B),
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 2),
              // Learn button
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.school, color: Colors.white70, size: 24),
                onPressed: onLearnPressed,
                tooltip: 'Learn Mode',
              ),
              const SizedBox(width: 2),
              // Settings button
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.settings, color: Colors.white70, size: 24),
                onPressed: onSettingsPressed,
                tooltip: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
