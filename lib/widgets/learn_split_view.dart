import 'package:flutter/material.dart';
import '../utils/app_layout.dart';
import '../utils/premium_manager.dart';
import 'alg_library_screen.dart';

/// Shows a method tutorial with the algorithm library beside it on wide
/// screens (iPhone Duo unfolded, iPad/phone landscape). On narrow screens,
/// or without library access, the tutorial is shown on its own.
///
/// The library runs in its own [Navigator] so its sheets stay in the right
/// pane; the tutorial's back button closes the whole view.
class LearnSplitView extends StatelessWidget {
  final Widget guide;

  const LearnSplitView({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    if (!AppLayout.isWide(context) ||
        !PremiumManager().canAccessFeature('alg_library')) {
      return guide;
    }
    return ColoredBox(
      color: const Color(0xFF0D0D1A),
      child: Row(
        children: [
          Expanded(child: guide),
          const VerticalDivider(width: 1, thickness: 1, color: Colors.white12),
          Expanded(
            child: ClipRect(
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute(
                  builder: (_) => const AlgLibraryScreen(showBackButton: false),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
