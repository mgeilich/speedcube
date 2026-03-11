import 'package:flutter/material.dart';
import '../utils/haptic_service.dart';

class TapeDeckControls extends StatelessWidget {
  final bool isPlaying;
  final bool isRewinding;
  final bool isFastForwarding;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPlayPause;
  final VoidCallback onRewind;
  final VoidCallback onFastForward;
  final VoidCallback onJumpToStart;
  final VoidCallback onJumpToEnd;
  final Color activeColor;

  const TapeDeckControls({
    super.key,
    required this.isPlaying,
    required this.isRewinding,
    required this.isFastForwarding,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPlayPause,
    required this.onRewind,
    required this.onFastForward,
    required this.onJumpToStart,
    required this.onJumpToEnd,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isShort = MediaQuery.of(context).size.height < 750;
    return Container(
      padding: EdgeInsets.symmetric(vertical: isShort ? 8 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            icon: Icons.first_page,
            onPressed: hasPrevious ? onJumpToStart : null,
            tooltip: "Jump to Start",
          ),
          const SizedBox(width: 8),
          _buildControlButton(
            icon: Icons.fast_rewind,
            onPressed: hasPrevious ? onRewind : null,
            isActive: isRewinding,
            tooltip: "Rewind (2x)",
          ),
          const SizedBox(width: 16),
          _buildControlButton(
            icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            onPressed: (hasNext || isPlaying) ? onPlayPause : null,
            isLarge: true,
            isActive: isPlaying && !isRewinding && !isFastForwarding,
            color: activeColor,
            tooltip: isPlaying ? "Pause" : "Play",
          ),
          const SizedBox(width: 16),
          _buildControlButton(
            icon: Icons.fast_forward,
            onPressed: hasNext ? onFastForward : null,
            isActive: isFastForwarding,
            tooltip: "Fast Forward (2x)",
          ),
          const SizedBox(width: 8),
          _buildControlButton(
            icon: Icons.last_page,
            onPressed: hasNext ? onJumpToEnd : null,
            tooltip: "Jump to End",
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLarge = false,
    bool isActive = false,
    Color? color,
    String? tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed != null
            ? () {
                HapticService.impactMedium();
                onPressed();
              }
            : null,
        borderRadius: BorderRadius.circular(isLarge ? 32 : 24),
        child: Container(
          width: isLarge ? 64 : 48,
          height: isLarge ? 64 : 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? (color ?? const Color(0xFF818CF8)).withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: isActive
                  ? (color ?? const Color(0xFF818CF8)).withValues(alpha: 0.5)
                  : Colors.white10,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Icon(
            icon,
            color: onPressed == null
                ? Colors.white24
                : (isActive
                    ? (color ?? const Color(0xFF818CF8))
                    : Colors.white),
            size: isLarge ? 32 : 24,
          ),
        ),
      ),
    );
  }
}
