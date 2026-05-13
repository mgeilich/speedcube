import 'package:flutter/material.dart';
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
import 'solve_stats_sheet.dart';
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
  final String? solveStatus;
  final bool isAnimating;
  final CubeState cubeState;
  final int scrambleLength;
  final Function(int) onScrambleLengthChanged;
  final VoidCallback onScramble;
  final VoidCallback onRandomize;
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
    this.solveStatus,
    required this.isAnimating,
    required this.cubeState,
    required this.scrambleLength,
    required this.onScrambleLengthChanged,
    required this.onScramble,
    required this.onRandomize,
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
    this.moveLabels,
  });

  final Map<int, String>? moveLabels;


  @override
  Widget build(BuildContext context) {
    if (showingSolution) {
      return AnimatedBuilder(
        animation: analysisController,
        builder: (context, child) {
          return Expanded(
            child: Column(
              children: [
                // 1. Move Counter / Scrubber
                if (MediaQuery.of(context).size.height >= 700) ...[
                  const SizedBox(height: 12),
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
                        const SizedBox(width: 12),
                        Text(
                          moveLabels != null && moveLabels!.containsKey(moveIndex - solutionStartIndex)
                              ? moveLabels![moveIndex - solutionStartIndex]!
                              : '${moveIndex - solutionStartIndex}/${moveHistory.length - solutionStartIndex}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            HapticService.impactLight();
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (_) => SolveStatsSheet(controller: analysisController),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bar_chart_rounded, color: Colors.white70, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'STATS',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 2. Play Controls (Tape Deck)
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
                  onStepForward: analysisController.nextMove,
                  onStepBackward: analysisController.previousMove,
                  onJumpToStart: () => onSeek(0, immediate: true),
                  onJumpToEnd: () =>
                      onSeek(analysisController.solution.length, immediate: true),
                  activeColor:
                      SolveTheme.getStageColor(analysisController.stageName),
                ),
                const SizedBox(height: 12),

                // 3. Move Buttons (Timeline)
                if (showExplanations || isDemo) ...[
                  AnalysisTimeline(
                    controller: analysisController,
                  ),
                  const SizedBox(height: 12),
                ],

                // 4. Explanation Box
                if (showExplanations)
                  Expanded(
                    child: _buildExplanationBox(context),
                  )
                else
                  const Spacer(),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
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

  Widget _buildExplanationBox(BuildContext context) {
    final move = analysisController.currentMove;
    final index = analysisController.currentIndex;
    final bool isPremium = PremiumManager().isPremium;

    if (!isPremium && move != null && !isDemo) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.workspace_premium, color: Color(0xFFF59E0B), size: 32),
            const SizedBox(height: 12),
            const Text(
              "UNLOCK PRO EXPLANATIONS",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Upgrade to see the rationale and objective behind every move.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => const PremiumUpsellSheet(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("SEE ALL FEATURES", style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    if (move == null) {
      final isCurrent = index == 0;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent ? const Color(0xFF6366F1) : Colors.white12,
              width: isCurrent ? 1.5 : 1,
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "START",
                style: TextStyle(
                  color: Color(0xFF818CF8),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "The cube is in its initial scrambled state. Use the controls above to navigate the solution.",
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    final stageColor = SolveTheme.getStageColor(
        analysisController.moveStageNames[index - 1]);
    final objective = MoveExplainer.getObjective(
      move,
      analysisController.currentPhase,
      analysisController.states[index - 1],
      analysisController.states[index],
    );

    final stageName = analysisController.moveStageNames[index - 1];
    final stageDesc = analysisController.moveStageDescriptions[index - 1];
    final algorithmName = analysisController.moveAlgorithmNames[index - 1];
    final stageGoal = stageName != null ? MoveExplainer.getStageGoal(stageName) : null;
    final isKociemba = stageName == null;

    final fullObjective = (stageDesc != null && stageDesc.isNotEmpty) ? stageDesc : objective;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: stageColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (isKociemba
                            ? "PHASE ${index <= analysisController.phase1MoveCount ? 1 : 2}"
                            : stageName.toUpperCase()),
                    style: TextStyle(
                      color: stageColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (algorithmName != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFACC15).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      algorithmName.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFFACC15),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (stageGoal != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  stageGoal,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            Text(
              isKociemba
                  ? MoveExplainer.getRationale(
                      move,
                      index - 1,
                      analysisController.solution.length,
                      analysisController.states[index - 1],
                      analysisController.states[index],
                      phase: index <= analysisController.phase1MoveCount ? 1 : 2,
                    )
                  : fullObjective,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
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
        label: solveStatus ?? 'Solving...',
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
        onRandomize: onRandomize,
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
            onRandomize: onRandomize,
            isScrambling: isScrambling,
            isAnimating: isAnimating,
          ),
          const SizedBox(height: 16),
          if (isPremium)
            PremiumSolverSelector(
              isAnimating: isAnimating,
              isSolving: isSolving,
              solveStatus: solveStatus,
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
  final bool isSolving;
  final String? solveStatus;
  final Function({SolveMethod? method, bool showExplanations}) onSolve;
  final SolveMethod selectedMethod;
  final Function(SolveMethod) onMethodChanged;

  const PremiumSolverSelector({
    super.key,
    required this.isAnimating,
    required this.isSolving,
    this.solveStatus,
    required this.onSolve,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  State<PremiumSolverSelector> createState() => _PremiumSolverSelectorState();
}

class _PremiumSolverSelectorState extends State<PremiumSolverSelector> {
  String _getMethodDisplayName(SolveMethod method) {
    switch (method) {
      case SolveMethod.lbl:
        return 'Layer-by-Layer';
      case SolveMethod.cfop:
        return 'CFOP (Advanced)';
      case SolveMethod.roux:
        return 'Roux Method';
      case SolveMethod.zz:
        return 'ZZ (Speedcube)';
      case SolveMethod.kociemba:
        return 'Kociemba (Optimal)';
      case SolveMethod.petrus:
        return 'Petrus Method';
      case SolveMethod.heise:
        return 'Heise Method';
    }
  }

  String _getSolveButtonLabel(SolveMethod method) {
    switch (method) {
      case SolveMethod.lbl:
        return 'SOLVE LBL';
      case SolveMethod.cfop:
        return 'SOLVE CFOP';
      case SolveMethod.roux:
        return 'SOLVE ROUX';
      case SolveMethod.zz:
        return 'SOLVE ZZ';
      case SolveMethod.petrus:
        return 'SOLVE PETRUS';
      case SolveMethod.kociemba:
        return 'SOLVE OPTIMAL';
      case SolveMethod.heise:
        return 'SOLVE HEISE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedMethod = widget.selectedMethod;
    final isSolving = widget.isSolving;
    final isDisabled = widget.isAnimating || isSolving;
    
    const primaryColor = Color(0xFF6366F1);
    final activeColor = isSolving ? const Color(0xFF10B981) : primaryColor;
    final buttonColor = isDisabled && !isSolving ? primaryColor.withValues(alpha: 0.3) : activeColor;

    return Container(
      width: 300,
      height: 54,
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
        children: [
          // Primary Solve Action
          Expanded(
            child: InkWell(
              onTap: isDisabled ? null : () {
                HapticService.impactMedium();
                widget.onSolve(method: selectedMethod);
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_fix_high, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        isSolving ? (widget.solveStatus ?? 'Solving...') : _getSolveButtonLabel(selectedMethod),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Divider
          Container(
            width: 1,
            height: 30,
            color: Colors.white24,
          ),
          
          // Method Selector (Chevron)
          Theme(
            data: Theme.of(context).copyWith(
              cardColor: const Color(0xFF1E293B),
            ),
            child: PopupMenuButton<SolveMethod>(
              initialValue: selectedMethod,
              enabled: !isDisabled,
              onSelected: (method) {
                HapticService.selection();
                widget.onMethodChanged(method);
              },
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
              itemBuilder: (context) => SolveMethod.values.map((method) {
                return PopupMenuItem<SolveMethod>(
                  value: method,
                  child: Text(
                    _getMethodDisplayName(method),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }




}
