import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/cube_state.dart';
import '../models/cube_move.dart';
import '../controllers/analysis_controller.dart';
import '../models/solve_method.dart';
import '../utils/premium_manager.dart';
import '../utils/move_explainer.dart';
import '../utils/solve_theme.dart';
import '../utils/haptic_service.dart';
import 'analysis_timeline.dart';
import 'premium_upsell_sheet.dart';
import 'tape_deck_controls.dart';
import 'scramble_settings_panel.dart';

class SolveControls extends StatelessWidget {
  final bool showingSolution;
  final bool showExplanations;
  final int moveIndex;
  final int solutionStartIndex;
  final List<CubeMove> moveHistory;
  final AnalysisController analysisController;
  final bool isScrambling;
  final bool isSolving;
  final bool isAnimating;
  final CubeState cubeState;
  final int scrambleLength;
  final Function(int) onScrambleLengthChanged;
  final VoidCallback onScramble;
  final Function({SolveMethod? method, bool showExplanations}) onSolve;
  final Function(SolveMethod) onMethodChanged;
  final SolveMethod selectedMethod;
  final Function(int, {bool immediate}) onSeek;
  final VoidCallback onSeekStart;
  final VoidCallback onShowWebDemo;
  final bool isDemo;
  final VoidCallback? onCancelDemo;
  final VoidCallback? onReset;
  final bool canReset;
  final bool isScanned;
// final VoidCallback? onARMode; // Removed

  const SolveControls({
    super.key,
    required this.showingSolution,
    required this.showExplanations,
    required this.moveIndex,
    required this.solutionStartIndex,
    required this.moveHistory,
    required this.analysisController,
    required this.isScrambling,
    required this.isSolving,
    required this.isAnimating,
    required this.cubeState,
    required this.scrambleLength,
    required this.onScrambleLengthChanged,
    required this.onScramble,
    required this.onSolve,
    required this.onSeek,
    required this.onSeekStart,
    required this.onShowWebDemo,
    this.isDemo = false,
    this.onCancelDemo,
    this.onReset,
    this.canReset = false,
    required this.isScanned,
    required this.onMethodChanged,
    required this.selectedMethod,
  });

  void _showPhase2Info(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Phase 2 Rules",
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: const Text(
          MoveExplainer.phase2Note,
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Got it",
                style: TextStyle(color: Color(0xFF38BDF8))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showingSolution) {
      return Expanded(
        child: Stack(
          children: [
            Column(
              children: [
                if (MediaQuery.of(context).size.height >= 700) ...[
                  const SizedBox(height: 12),
                  // Progress scrubber
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        const Icon(Icons.history,
                            color: Colors.white54, size: 20),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14),
                              activeTrackColor: SolveTheme.getStageColor(
                                  analysisController.stageName),
                              inactiveTrackColor: Colors.white10,
                              thumbColor: SolveTheme.getStageColor(
                                  analysisController.stageName),
                            ),
                            child: Slider(
                              value: moveIndex.toDouble(),
                              min: solutionStartIndex.toDouble(),
                              max: moveHistory.length.toDouble(),
                              divisions:
                                  (moveHistory.length - solutionStartIndex) > 0
                                      ? moveHistory.length - solutionStartIndex
                                      : 1,
                              onChangeStart: (_) => onSeekStart(),
                              onChanged: (value) {
                                HapticService.selection();
                                final target = (value - solutionStartIndex)
                                    .round()
                                    .clamp(0,
                                        moveHistory.length - solutionStartIndex);
                                onSeek(target);
                              },
                              onChangeEnd: (value) {
                                final target = (value - solutionStartIndex)
                                    .round()
                                    .clamp(0,
                                        moveHistory.length - solutionStartIndex);
                                onSeek(target, immediate: true);
                              },
                            ),
                          ),
                        ),
                        Text(
                          '${moveIndex - solutionStartIndex}/${moveHistory.length - solutionStartIndex}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Tape Deck Controls
                TapeDeckControls(
                  isPlaying: analysisController.isPlaying,
                  isRewinding: analysisController.isRewinding,
                  isFastForwarding: analysisController.isFastForwarding,
                  hasPrevious: analysisController.hasPrevious,
                  hasNext: analysisController.hasNext,
                  onPlayPause: analysisController.isPlaying
                      ? analysisController.pause
                      : analysisController.play,
                  onRewind: analysisController.rewind,
                  onFastForward: () => analysisController.play(fast: true),
                  onJumpToStart: () => onSeek(0, immediate: true),
                  onJumpToEnd: () =>
                      onSeek(analysisController.solution.length, immediate: true),
// onARMode: onARMode, // Removed
                  activeColor:
                      SolveTheme.getStageColor(analysisController.stageName),
                ),
                const SizedBox(height: 12),

                // Analysis buttons (timeline)
                if (showExplanations || isDemo) ...[
                  AnalysisTimeline(
                    controller: analysisController,
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 16),

                // Move Explanation Area
                if (showExplanations && !isDemo)
                  Expanded(
                    child: AnimatedBuilder(
                      animation: analysisController,
                      builder: (context, child) {
                        final move = analysisController.currentMove;
                        final index = analysisController.currentIndex;

                        final bool isPremium = PremiumManager().isPremium;

                        if (!isPremium && move != null) {
                          // PRO Teaser for non-premium users
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF6366F1)
                                    .withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.workspace_premium,
                                    color: Color(0xFFF59E0B), size: 40),
                                const SizedBox(height: 16),
                                const Text(
                                  "UNLOC PRO EXPLANATIONS",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Upgrade to see the rationale and objective behind every move.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      isScrollControlled: true,
                                      builder: (_) =>
                                          const PremiumUpsellSheet(),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF59E0B),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text("SEE ALL FEATURES"),
                                ),
                              ],
                            ),
                          );
                        }

                        if (move == null) {
                          // Initial "Start" state
                          final isCurrent = index == 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            child: GestureDetector(
                              onTap: () => onSeek(0, immediate: true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCurrent
                                        ? const Color(0xFF6366F1)
                                        : Colors.white12,
                                    width: isCurrent ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    if (index < analysisController.currentIndex)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 12),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF10B981),
                                          size: 18,
                                        ),
                                      )
                                    else
                                      const SizedBox(width: 4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "START",
                                            style: TextStyle(
                                              color: Color(0xFF818CF8),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Scrambled state",
                                            style: TextStyle(
                                              color: isCurrent
                                                  ? Colors.white
                                                  : Colors.white70,
                                              fontSize: 13,
                                              fontWeight: isCurrent
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                        }

                        // Compact tappable summary row - ONLY FOR PREMIUM
                        final stageColor = SolveTheme.getStageColor(
                            analysisController.moveStageNames[index - 1]);
                        final phaseColor = stageColor;
                        final objective = MoveExplainer.getObjective(
                          move,
                          analysisController.currentPhase,
                          analysisController.states[index - 1],
                          analysisController.states[index],
                        );

                        final isCompleted =
                            index < analysisController.currentIndex;
                        final isCurrent =
                            index == analysisController.currentIndex;

                        final stageName =
                            analysisController.moveStageNames[index - 1];
                        final stageDesc =
                            analysisController.moveStageDescriptions[index - 1];
                        final algorithmName =
                            analysisController.moveAlgorithmNames[index - 1];
                        final stageGoal = stageName != null
                            ? MoveExplainer.getStageGoal(stageName)
                            : null;
                        final isKociemba = stageName == null;

                        final fullObjective =
                            (stageDesc != null && stageDesc.isNotEmpty)
                                ? stageDesc
                                : objective;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 4),
                          child: GestureDetector(
                            onTap: () {
                              if (analysisController.isPlaying) {
                                onSeekStart();
                                onSeek(index);
                              } else {
                                onSeek(index);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      isCurrent ? phaseColor : Colors.white12,
                                  width: isCurrent ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (isCompleted)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 12),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF10B981),
                                        size: 18,
                                      ),
                                    )
                                  else
                                    const SizedBox(width: 4),
                                  // Move info
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 2),
                                            child: Row(
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    if (isKociemba &&
                                                        index >
                                                            analysisController
                                                                .phase1MoveCount) {
                                                      _showPhase2Info(context);
                                                    }
                                                  },
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        (isKociemba
                                                            ? "PHASE ${index <= analysisController.phase1MoveCount ? 1 : 2}"
                                                            : stageName
                                                                .toUpperCase()),
                                                        style: TextStyle(
                                                          color: isCompleted
                                                              ? Colors.white38
                                                              : stageColor,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                      if (isKociemba &&
                                                          index >
                                                              analysisController
                                                                  .phase1MoveCount) ...[
                                                        const SizedBox(width: 4),
                                                        Icon(
                                                          Icons.info_outline,
                                                          size: 10,
                                                          color: isCompleted
                                                              ? Colors.white38
                                                              : stageColor,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                if (algorithmName != null) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 5,
                                                            vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: (isCompleted
                                                              ? Colors.white12
                                                              : const Color(
                                                                  0xFFFACC15))
                                                          .withValues(
                                                              alpha: 0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      border: Border.all(
                                                        color: (isCompleted
                                                                ? Colors.white12
                                                                : const Color(
                                                                    0xFFFACC15))
                                                            .withValues(
                                                                alpha: 0.3),
                                                        width: 0.5,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      algorithmName.toUpperCase(),
                                                      style: TextStyle(
                                                        color: isCompleted
                                                            ? Colors.white38
                                                            : const Color(
                                                                0xFFFACC15),
                                                        fontSize: 8,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (stageGoal != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 6),
                                              child: Text(
                                                stageGoal,
                                                style: TextStyle(
                                                  color: isCompleted
                                                      ? Colors.white24
                                                      : Colors.white70,
                                                  fontSize: 11,
                                                  fontStyle: FontStyle.italic,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ),
                                          Text(
                                            isKociemba
                                                ? MoveExplainer.getRationale(
                                                    move,
                                                    index - 1,
                                                    analysisController
                                                        .solution.length,
                                                    analysisController
                                                        .states[index - 1],
                                                    analysisController
                                                        .states[index],
                                                    phase: index <=
                                                            analysisController
                                                                .phase1MoveCount
                                                        ? 1
                                                        : 2,
                                                  )
                                                : fullObjective,
                                            style: TextStyle(
                                              color: isCompleted
                                                  ? Colors.white38
                                                  : Colors.white,
                                              fontSize: 13,
                                              fontWeight: isCurrent
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              fontStyle: isKociemba
                                                  ? FontStyle.italic
                                                  : FontStyle.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(height: 12),
              ],
            ),
          ],
        ),
      );
    } else {
      return Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: _buildMainActionButton(context),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildMainActionButton(BuildContext context) {
    if (isDemo) {
      return _buildButton(
        icon: Icons.close,
        label: 'CANCEL',
        onPressed: onCancelDemo,
        color: const Color(0xFFEF4444),
        width: 280,
      );
    } else if (isScrambling) {
      return _buildButton(
        icon: Icons.shuffle,
        label: 'Scrambling...',
        onPressed: null,
        color: const Color(0xFFF59E0B),
        width: 280,
      );
    } else if (isSolving) {
      return _buildButton(
        icon: Icons.auto_fix_high,
        label: 'Solving...',
        onPressed: null,
        color: const Color(0xFF22C55E),
        width: 280,
      );
    } else if (showingSolution) {
      return const SizedBox.shrink();
    } else if (cubeState.isSolved && !isScrambling && !isSolving) {
      return ScrambleSettingsPanel(
        scrambleLength: scrambleLength,
        onLengthChanged: onScrambleLengthChanged,
        onScramble: onScramble,
        isScrambling: isScrambling,
        isAnimating: isAnimating,
      );
    } else {
      final bool isPremium = PremiumManager().isPremium;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScrambleSettingsPanel(
            scrambleLength: scrambleLength,
            onLengthChanged: onScrambleLengthChanged,
            onScramble: onScramble,
            isScrambling: isScrambling,
            isAnimating: isAnimating,
          ),
          const SizedBox(height: 16),
          if (isPremium)
            PremiumSolverSelector(
              isAnimating: isAnimating,
              onSolve: onSolve,
              selectedMethod: selectedMethod,
              onMethodChanged: onMethodChanged,
            )
          else
            _buildButton(
              icon: Icons.auto_fix_high,
              label: 'Solve',
              onPressed: isAnimating
                  ? null
                  : () => onSolve(method: SolveMethod.kociemba),
              color: const Color(0xFF6366F1),
              width: 280,
            ),
        ],
      );
    }
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    double? width,
    bool isPremiumGated = false,
  }) {
    final isDisabled = onPressed == null;
    final buttonColor = isDisabled ? color.withValues(alpha: 0.3) : color;

    return GestureDetector(
      onTap: onPressed != null
          ? () {
              HapticService.impactMedium();
              onPressed();
            }
          : null,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isDisabled
              ? null
              : LinearGradient(
                  colors: [buttonColor, buttonColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isDisabled ? buttonColor : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: buttonColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (isPremiumGated) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PremiumSolverSelector extends StatefulWidget {
  final bool isAnimating;
  final Function({SolveMethod? method, bool showExplanations}) onSolve;
  final SolveMethod selectedMethod;
  final Function(SolveMethod) onMethodChanged;

  const PremiumSolverSelector({
    super.key,
    required this.isAnimating,
    required this.onSolve,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  State<PremiumSolverSelector> createState() => _PremiumSolverSelectorState();
}

class _PremiumSolverSelectorState extends State<PremiumSolverSelector> {
  @override
  Widget build(BuildContext context) {
    final selectedMethod = widget.selectedMethod;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 320,
          child: CupertinoSlidingSegmentedControl<SolveMethod>(
            groupValue: selectedMethod,
            children: {
              SolveMethod.lbl: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('LBL', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
              SolveMethod.cfop: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('CFOP', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
              SolveMethod.roux: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Roux', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
              SolveMethod.kociemba: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Kociemba', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            },
            backgroundColor: Colors.white12,
            thumbColor: const Color(0xFF6366F1).withValues(alpha: 0.8),
            onValueChanged: (method) {
              if (method != null) {
                HapticService.selection();
                widget.onMethodChanged(method);
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildSolveButton(
          icon: Icons.auto_fix_high,
          label: _solveButtonLabel(selectedMethod),
          onPressed: widget.isAnimating ? null : () => widget.onSolve(method: selectedMethod),
          color: const Color(0xFF6366F1),
          width: 280,
        ),
      ],
    );
  }

  String _solveButtonLabel(SolveMethod method) {
    switch (method) {
      case SolveMethod.kociemba:
        return 'Solve Kociemba';
      case SolveMethod.lbl:
        return 'Solve Layer-by-Layer';
      case SolveMethod.cfop:
        return 'Solve CFOP';
      case SolveMethod.roux:
        return 'Solve Roux';
    }
  }

  Widget _buildSolveButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    double? width,
  }) {
    final isDisabled = onPressed == null;
    final buttonColor = isDisabled ? color.withValues(alpha: 0.3) : color;

    return GestureDetector(
      onTap: onPressed != null
          ? () {
              HapticService.impactMedium();
              onPressed();
            }
          : null,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isDisabled
              ? null
              : LinearGradient(
                  colors: [buttonColor, buttonColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isDisabled ? buttonColor : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: buttonColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
