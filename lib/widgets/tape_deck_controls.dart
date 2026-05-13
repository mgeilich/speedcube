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
  final VoidCallback onStepForward;
  final VoidCallback onStepBackward;
  final VoidCallback onJumpToStart;
  final VoidCallback onJumpToEnd;
// final VoidCallback? onARMode; // Removed
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
    required this.onStepForward,
    required this.onStepBackward,
    required this.onJumpToStart,
    required this.onJumpToEnd,
// this.onARMode, // Removed
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isShort = MediaQuery.of(context).size.height < 750;
    final smallButtonSize = isShort ? 38.0 : 42.0;
    final spacing = isShort ? 4.0 : 8.0;

    return Container(
      padding: EdgeInsets.symmetric(vertical: isShort ? 8 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            icon: Icons.first_page,
            onPressed: hasPrevious ? onJumpToStart : null,
            size: smallButtonSize,
            tooltip: "Jump to Start",
          ),
          SizedBox(width: spacing),
          _buildControlButton(
            icon: Icons.skip_previous_rounded,
            onPressed: hasPrevious ? onStepBackward : null,
            size: smallButtonSize,
            tooltip: "Step Back",
          ),
          SizedBox(width: spacing),
          _buildControlButton(
            icon: Icons.fast_rewind,
            onPressed: hasPrevious ? onRewind : null,
            isActive: isRewinding,
            size: smallButtonSize,
            tooltip: "Rewind (2x)",
          ),
          SizedBox(width: spacing * 2),
          _buildControlButton(
            icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            onPressed: (hasNext || isPlaying) ? onPlayPause : null,
            isLarge: true,
            isActive: isPlaying && !isRewinding && !isFastForwarding,
            color: activeColor,
            tooltip: isPlaying ? "Pause" : "Play",
          ),
          SizedBox(width: spacing * 2),
          _buildControlButton(
            icon: Icons.fast_forward,
            onPressed: hasNext ? onFastForward : null,
            isActive: isFastForwarding,
            size: smallButtonSize,
            tooltip: "Fast Forward (2x)",
          ),
          SizedBox(width: spacing),
          _buildControlButton(
            icon: Icons.skip_next_rounded,
            onPressed: hasNext ? onStepForward : null,
            size: smallButtonSize,
            tooltip: "Step Forward",
          ),
          SizedBox(width: spacing),
          _buildControlButton(
            icon: Icons.last_page,
            onPressed: hasNext ? onJumpToEnd : null,
            size: smallButtonSize,
            tooltip: "Jump to End",
          ),
// Removed AR Mode button
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLarge = false,
    double? size,
    bool isActive = false,
    Color? color,
    String? tooltip,
  }) {
    final double buttonSize = size ?? (isLarge ? 64 : 48);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed != null
            ? () {
                HapticService.impactMedium();
                onPressed();
              }
            : null,
        borderRadius: BorderRadius.circular(buttonSize / 2),
        child: Container(
          width: buttonSize,
          height: buttonSize,
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
            size: isLarge ? 32 : (buttonSize * 0.5),
          ),
        ),
      ),
    );
  }
}
