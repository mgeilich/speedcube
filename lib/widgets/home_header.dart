import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/premium_manager.dart';
import 'premium_upsell_sheet.dart';
import 'alg_library_screen.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onScanPressed;
  final VoidCallback onLearnPressed;

  const HomeHeader({
    super.key,
    required this.onScanPressed,
    required this.onLearnPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.view_in_ar, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            "SpeedCube AR",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Spacer(),
          // Scan button
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.camera_alt,
                    color: Colors.white70, size: 26),
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
                  right: 4,
                  bottom: 4,
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
          const SizedBox(width: 4),
          // Learn button
          IconButton(
            icon: const Icon(Icons.school, color: Colors.white70, size: 26),
            onPressed: onLearnPressed,
            tooltip: 'Learn Mode',
          ),
          const SizedBox(width: 4),
          // Algorithm Library button
          IconButton(
            icon: const Icon(Icons.menu_book_rounded,
                color: Colors.white70, size: 26),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AlgLibraryScreen(),
              ),
            ),
            tooltip: 'Algorithm Library',
          ),
        ],
      ),
    );
  }
}
