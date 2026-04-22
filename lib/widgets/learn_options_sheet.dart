import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/premium_manager.dart';

class LearnOptionsSheet extends StatelessWidget {
  final VoidCallback onSelectIntroduction;
  final VoidCallback onSelectLayerByLayerMethod;
  final VoidCallback onSelectCfopMethod;
  final VoidCallback onSelectRouxMethod;
  final VoidCallback onSelectZzMethod;
  final VoidCallback onSelectPetrusMethod;

  const LearnOptionsSheet({
    super.key,
    required this.onSelectIntroduction,
    required this.onSelectLayerByLayerMethod,
    required this.onSelectCfopMethod,
    required this.onSelectRouxMethod,
    required this.onSelectZzMethod,
    required this.onSelectPetrusMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Learn to Solve',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white38, size: 26),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Options list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildOptionCard(
                    icon: Icons.info_outline,
                    title: 'Introduction to the Cube',
                    description:
                        'Learn the basics: pieces, faces, and how the cube moves.',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectIntroduction();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildOptionCard(
                    icon: Icons.layers,
                    title: 'Layer-by-Layer Tutorial',
                    description: 'Learn to solve your first cube step-by-step.',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectLayerByLayerMethod();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildOptionCard(
                    icon: Icons.bolt,
                    isAdvanced: true,
                    isPremium: true,
                    title: 'CFOP Tutorial',
                    description: 'The next step to a faster solution',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectCfopMethod();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildOptionCard(
                    icon: Icons.extension,
                    isAdvanced: true,
                    isPremium: true,
                    title: 'Roux Method',
                    description: 'Innovative block building and low move counts',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectRouxMethod();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildOptionCard(
                    icon: Icons.architecture,
                    isAdvanced: true,
                    isPremium: true,
                    title: 'ZZ Method',
                    description: 'The efficiency master: No rotations, fewer moves',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectZzMethod();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildOptionCard(
                    icon: Icons.view_in_ar_rounded,
                    isAdvanced: true,
                    isPremium: true,
                    title: 'Petrus Method',
                    description: 'Build blocks, orient edges, and solve efficiently',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectPetrusMethod();
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isAdvanced = false,
    bool isPremium = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAdvanced
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                    : const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isAdvanced
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isPremium &&
                          !kIsWeb &&
                          !PremiumManager().isPremium) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.5)),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
