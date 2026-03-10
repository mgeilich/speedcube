import 'package:flutter/material.dart';
import '../models/cube_move.dart';
import '../controllers/analysis_controller.dart';

/// Horizontal scrolling timeline showing all moves in the solution.
class AnalysisTimeline extends StatefulWidget {
  final AnalysisController controller;
  const AnalysisTimeline({
    super.key,
    required this.controller,
  });

  @override
  State<AnalysisTimeline> createState() => _AnalysisTimelineState();
}

class _AnalysisTimelineState extends State<AnalysisTimeline> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // Auto-scroll to keep current move visible
    if (_scrollController.hasClients) {
      final index = widget.controller.currentIndex;
      final itemWidth = 72.0; // Width of each move chip + spacing
      final targetOffset = index * itemWidth - 100; // Center it

      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A).withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: widget.controller.solution.length +
                  1, // Start + Moves (Solved is reachable via last move)
              itemBuilder: (context, index) {
                final isCurrent = index == widget.controller.currentIndex;
                final isPast = index < widget.controller.currentIndex;

                if (index == 0) {
                  // Start chip
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _StartChip(
                      isCurrent: isCurrent,
                      onTap: () => widget.controller.goToMove(0),
                    ),
                  );
                }

                // Moves are at index 1 to N
                final moveIndex = index - 1;
                final move = widget.controller.solution[moveIndex];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _MoveChip(
                    move: move,
                    isCurrent: isCurrent,
                    isPast: isPast,
                    onTap: () => widget.controller.goToMove(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual move chip in the timeline.
class _MoveChip extends StatelessWidget {
  final CubeMove move;
  final bool isCurrent;
  final bool isPast;
  final VoidCallback onTap;

  const _MoveChip({
    required this.move,
    required this.isCurrent,
    required this.isPast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final faceColor = _getFaceColor(move.face);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        height: 56,
        decoration: BoxDecoration(
          color: isCurrent
              ? faceColor.withValues(alpha: 0.3)
              : isPast
                  ? const Color(0xFF64748B).withValues(alpha: 0.2)
                  : const Color(0xFF64748B).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? faceColor
                : isPast
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
            width: isCurrent ? 3 : 1.5,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: faceColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            move.toString(),
            style: TextStyle(
              color: isCurrent
                  ? Colors.white
                  : isPast
                      ? Colors.white54
                      : Colors.white70,
              fontSize: isCurrent ? 20 : 18,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  Color _getFaceColor(CubeFace face) {
    switch (face) {
      case CubeFace.u:
        return const Color(0xFFFFFFFF); // White
      case CubeFace.d:
        return const Color(0xFFFFD500); // Yellow
      case CubeFace.f:
        return const Color(0xFF009B48); // Green
      case CubeFace.b:
        return const Color(0xFF0046AD); // Blue
      case CubeFace.r:
        return const Color(0xFFB71234); // Red
      case CubeFace.l:
        return const Color(0xFFFF5800); // Orange
    }
  }
}

/// Specialized chip showing the starting state.
class _StartChip extends StatelessWidget {
  final bool isCurrent;
  final VoidCallback onTap;

  const _StartChip({
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const startColor = Color(0xFF6366F1);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 56,
        decoration: BoxDecoration(
          color: isCurrent
              ? startColor.withValues(alpha: 0.3)
              : const Color(0xFF64748B).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? startColor : Colors.white.withValues(alpha: 0.1),
            width: isCurrent ? 3 : 1.5,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: startColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag, color: startColor, size: 20),
            SizedBox(height: 2),
            Text(
              'START',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
