import 'package:flutter/material.dart';
import 'dart:async';
import '../models/cube_state.dart';
import '../models/cube_move.dart';
import '../animation/cube_animation_controller.dart';
import '../controllers/analysis_controller.dart';

import '../utils/premium_manager.dart';
import '../utils/haptic_service.dart';
import '../services/solver_service.dart';
// import '../widgets/ar_guided_solver_screen.dart'; // Removed
// import '../controllers/guided_solver_controller.dart'; // Removed

enum SolveMethod { kociemba, lbl, cfop }

class HomeController extends ChangeNotifier {
  final TickerProvider vsync;

  CubeState _cubeState = CubeState.solved();
  CubeState _baseCubeState = CubeState.solved();
  late CubeAnimationController _animationController;
  late AnalysisController _analysisController;

  double _rotationX = -0.45;
  double _rotationY = 0.75;
  bool _isScanned = false;

  List<CubeMove> _moveHistory = [];
  int _moveIndex = 0;
  int _solutionStartIndex = 0;
  bool _showingSolution = false;
  bool _showExplanations = false;
  CubeState? _savedState;

  bool _isScrambling = false;
  bool _isSolving = false;
  int? _activeDemoStepIndex;
  String? _activeDemoType;
  Map<CubeFace, Map<int, String>>? _stickerLabels;
  Map<CubeFace, Map<int, String>>? _initialStickerLabels;
  CubeState? _initialCubeState;

  // Callback for when a demo finishes (used by main.dart to show guide)
  void Function(int? stepIndex, String? demoType)? onDemoFinished;
  int _scrambleLength = 20;
  int? _guideSeekTarget;
  final List<bool> _moveDirectionQueue = [];
  int _solvesCompleted = 0;
  VoidCallback? onReviewPromptRequested;
  VoidCallback? onPremiumUpsellRequested;

  // Tutorial Progress Persistence
  int? _lastCfopStepIndex;
  double? _lastCfopScrollOffset;
  int? _lastLblStepIndex;
  int? _lastOllSubTabIndex;
  int? _lastPllSubTabIndex;
  int? _lastF2lSubTabIndex;

  HomeController({required this.vsync}) {
    _animationController = CubeAnimationController(
      vsync: vsync,
      moveDuration: const Duration(milliseconds: 400),
      onUpdate: () => notifyListeners(),
      onMoveComplete: _onMoveComplete,
    );

    _analysisController = AnalysisController(
      onPlayRequest: () {
        if (!_analysisController.hasNext) return;
        _analysisController.setPlayingInternal(true);
        handleAnalysisNext();
      },
      onRewindRequest: () {
        if (!_analysisController.hasPrevious) return;
        _analysisController.setRewindingInternal(true);
        handleAnalysisPrevious();
      },
      onPauseRequest: () {
        _analysisController.setPlayingInternal(false);
        _animationController.clearQueue();
        _moveDirectionQueue.clear();
        _guideSeekTarget = null;
      },
      onNextRequest: handleAnalysisNext,
      onPreviousRequest: handleAnalysisPrevious,
      onSeekRequest: (index, {bool immediate = false}) =>
          handleAnalysisSeek(index, immediate: immediate),
    );

    _analysisController.addListener(notifyListeners);

    PremiumManager().addListener(_onPremiumChanged);
  }

  // Getters
  CubeState get cubeState => _cubeState;
  CubeAnimationController get animationController => _animationController;
  AnalysisController get analysisController => _analysisController;
  double get rotationX => _rotationX;
  double get rotationY => _rotationY;
  List<CubeMove> get moveHistory => _moveHistory;
  int get solvesCompleted => _solvesCompleted;
  int get moveIndex => _moveIndex;
  int get solutionStartIndex => _solutionStartIndex;
  bool get showingSolution => _showingSolution;
  bool get isSolving => _isSolving;
  bool get isScrambling => _isScrambling;
  int? get activeDemoStepIndex => _activeDemoStepIndex;
  bool get isDemo => _activeDemoStepIndex != null && _showingSolution;
  bool get canReset =>
      _savedState != null && (_showingSolution || !_cubeState.isSolved);
  int get scrambleLength => _scrambleLength;
  bool get showExplanations => _showExplanations;
  Map<CubeFace, Map<int, String>>? get stickerLabels => _stickerLabels;
  bool get isScanned => _isScanned;
  int? get lastCfopStepIndex => _lastCfopStepIndex;
  double? get lastCfopScrollOffset => _lastCfopScrollOffset;
  int? get lastLblStepIndex => _lastLblStepIndex;
  int? get lastOllSubTabIndex => _lastOllSubTabIndex;
  int? get lastPllSubTabIndex => _lastPllSubTabIndex;
  int? get lastF2lSubTabIndex => _lastF2lSubTabIndex;

  // Setters
  set rotationX(double value) {
    _rotationX = value;
    notifyListeners();
  }

  set rotationY(double value) {
    _rotationY = value;
    notifyListeners();
  }

  set scrambleLength(int value) {
    if (value > 20 && !PremiumManager().isPremium) {
      onPremiumUpsellRequested?.call();
      return;
    }
    _scrambleLength = value;
    notifyListeners();
  }

  set showingSolution(bool value) {
    _showingSolution = value;
    notifyListeners();
  }

  set showExplanations(bool value) {
    _showExplanations = value;
    notifyListeners();
  }

  void updateCfopProgress(int stepIndex, double scrollOffset, {int? ollSubIndex, int? pllSubIndex, int? f2lSubIndex}) {
    _lastCfopStepIndex = stepIndex;
    _lastCfopScrollOffset = scrollOffset;
    if (ollSubIndex != null) _lastOllSubTabIndex = ollSubIndex;
    if (pllSubIndex != null) _lastPllSubTabIndex = pllSubIndex;
    if (f2lSubIndex != null) _lastF2lSubTabIndex = f2lSubIndex;
    notifyListeners();
  }

  void updateLblProgress(int stepIndex) {
    _lastLblStepIndex = stepIndex;
    notifyListeners();
  }

  void _onMoveComplete() {
    if (_animationController.currentMove != null) {
      final currentMove = _animationController.currentMove!;
      if (_stickerLabels != null) {
        final newLabels = <CubeFace, Map<int, String>>{};
        _stickerLabels!.forEach((face, fLabels) {
          fLabels.forEach((index, label) {
            final next = _cubeState.stickerAfterMove(face, index, currentMove);
            newLabels.putIfAbsent(next.key, () => {})[next.value] = label;
          });
        });
        _stickerLabels = newLabels;
      }

      _cubeState = _cubeState.applyMove(currentMove);

      bool isReverse = false;
      if (_moveDirectionQueue.isNotEmpty) {
        isReverse = _moveDirectionQueue.removeAt(0);
      }

      if (isReverse) {
        _moveIndex--;
      } else {
        _moveIndex++;
      }

      // Safeguard index against solution boundaries
      final solutionLength = _analysisController.solution.length;
      _moveIndex = _moveIndex.clamp(
          _solutionStartIndex, _solutionStartIndex + solutionLength);

      if (_showingSolution) {
        final vizIndex = _moveIndex - _solutionStartIndex;

        // Haptic feedback for move completion during solution playback
        HapticService.impactLight();

        // Always update analysis state to keep UI in sync
        _analysisController.setAnimatingIndexInternal(null);
        _analysisController.updateIndexInternal(vizIndex);

        if (_guideSeekTarget != null) {
          if (vizIndex == _guideSeekTarget) {
            _guideSeekTarget = null;
            _analysisController.setPlayingInternal(false);
            notifyListeners();
            return;
          }
          final diffCount = (_guideSeekTarget! - vizIndex).abs();
          Duration moveDuration;
          Duration nextMoveDelay;

          if (diffCount >= 10) {
            moveDuration = const Duration(milliseconds: 60);
            nextMoveDelay = const Duration(milliseconds: 10);
          } else if (diffCount >= 5) {
            moveDuration = const Duration(milliseconds: 100);
            nextMoveDelay = const Duration(milliseconds: 20);
          } else if (diffCount >= 2) {
            moveDuration = const Duration(milliseconds: 180);
            nextMoveDelay = const Duration(milliseconds: 40);
          } else {
            moveDuration = Duration(
                milliseconds: (400 / _analysisController.speed).round());
            nextMoveDelay = Duration(
                milliseconds: (100 / _analysisController.speed).round());
          }

          final diff = _guideSeekTarget! - vizIndex;
          if (diff > 0 && _analysisController.hasNext) {
            Future.delayed(nextMoveDelay, () {
              if (_guideSeekTarget != null) {
                handleAnalysisNext(overrideDuration: moveDuration);
              }
            });
          } else if (diff < 0 && _analysisController.hasPrevious) {
            Future.delayed(nextMoveDelay, () {
              if (_guideSeekTarget != null) {
                handleAnalysisPrevious(overrideDuration: moveDuration);
              }
            });
          }
          notifyListeners();
          return;
        }

        if (_analysisController.isPlaying) {
          final bool isFast = _analysisController.isFastForwarding ||
              _analysisController.isRewinding;
          final int delayMs = (isFast
                  ? 200 / _analysisController.speed
                  : 400 / _analysisController.speed)
              .round();

          if (_analysisController.isRewinding) {
            if (_analysisController.hasPrevious) {
              Future.delayed(Duration(milliseconds: delayMs), () {
                if (_showingSolution &&
                    _analysisController.isRewinding &&
                    _analysisController.hasPrevious) {
                  handleAnalysisPrevious();
                } else if (_showingSolution &&
                    _analysisController.isRewinding) {
                  _analysisController.setPlayingInternal(false);
                }
              });
            } else {
              _analysisController.setPlayingInternal(false);
            }
          } else {
            if (_analysisController.hasNext) {
              Future.delayed(Duration(milliseconds: delayMs), () {
                if (_showingSolution &&
                    _analysisController.isPlaying &&
                    !_analysisController.isRewinding &&
                    _analysisController.hasNext) {
                  handleAnalysisNext();
                } else {
                  _analysisController.setPlayingInternal(false);
                }
              });
            } else {
              _analysisController.setPlayingInternal(false);
            }
          }
        }
      }

      if (_cubeState.isSolved &&
          _showingSolution &&
          _moveIndex == _moveHistory.length) {
        _solvesCompleted++;
        if (_solvesCompleted == 3 && onReviewPromptRequested != null) {
          onReviewPromptRequested!();
        }
      }
      notifyListeners();
    }

    if (_animationController.queueLength <= 1) {
      _isSolving = false;
      _isScrambling = false;
      notifyListeners();
    }
  }

  void _onPremiumChanged() {
    if (!PremiumManager().isPremium && _scrambleLength > 20) {
      _scrambleLength = 20;
    }
    notifyListeners();
  }

  void _queueAnalysisMove(CubeMove move, bool isReverse,
      {Duration? overrideDuration}) {
    final double baseDuration = (_analysisController.isFastForwarding ||
            _analysisController.isRewinding)
        ? 200.0
        : 400.0;

    _animationController.setSpeed(overrideDuration ??
        Duration(
            milliseconds: (baseDuration / _analysisController.speed).round()));

    _moveDirectionQueue.add(isReverse);
    _animationController.queueMoves([move]);
    notifyListeners();
  }

  void handleAnalysisNext({Duration? overrideDuration}) {
    if (!_showingSolution || !_analysisController.hasNext) return;

    final move = _analysisController.solution[_analysisController.currentIndex];
    _analysisController.setAnimatingIndexInternal(_analysisController.currentIndex + 1);
    _queueAnalysisMove(move, false, overrideDuration: overrideDuration);
  }

  void handleAnalysisPrevious({Duration? overrideDuration}) {
    if (!_showingSolution || !_analysisController.hasPrevious) return;

    final prevMoveIndex = _analysisController.currentIndex - 1;
    _analysisController.setAnimatingIndexInternal(_analysisController.currentIndex);
    final move = _analysisController.solution[prevMoveIndex];
    final inverseMove = move.inverse;

    _queueAnalysisMove(inverseMove, true, overrideDuration: overrideDuration);
  }

  void handleAnalysisSeekStart() {
    if (!_showingSolution) return;
    _analysisController.pause();
    _guideSeekTarget = null; // Reset any persistent seek target
    _animationController.clearQueue();
    _moveDirectionQueue.clear();
    notifyListeners();
  }

  void handleAnalysisSeek(int index, {bool immediate = false}) {
    if (!_showingSolution) return;

    final currentIndex = _moveIndex - _solutionStartIndex;
    if (index == currentIndex) {
      _guideSeekTarget = null;
      return;
    }

    if (immediate) {
      _analysisController.pause();
      _guideSeekTarget = null;
      _animationController.clearQueue();
      _moveDirectionQueue.clear();

      // Update state instantly
      _cubeState = _analysisController.states[index];
      _moveIndex = _solutionStartIndex + index;

      // Recalculate sticker labels if in a demo
      if (_stickerLabels != null &&
          _initialStickerLabels != null &&
          _initialCubeState != null) {
        final Map<CubeFace, Map<int, String>> newLabels = _initialStickerLabels!
            .map((face, labels) => MapEntry(
                face,
                labels
                    .map<int, String>((k, v) => MapEntry<int, String>(k, v))));

        CubeState tempState = _initialCubeState!;
        for (int i = 0; i < index; i++) {
          final move = _analysisController.solution[i];

          // Simulate label movement for each move up to the target index
          final updatedLabels = <CubeFace, Map<int, String>>{};
          newLabels.forEach((face, fLabels) {
            fLabels.forEach((idx, label) {
              final next = tempState.stickerAfterMove(face, idx, move);
              updatedLabels.putIfAbsent(next.key, () => {})[next.value] = label;
            });
          });

          // Clear and refill newLabels
          newLabels.clear();
          newLabels.addAll(updatedLabels);
          tempState = tempState.applyMove(move);
        }
        _stickerLabels = newLabels;
      }

      _analysisController.updateIndexInternal(index);
      notifyListeners();
      return;
    }

    _guideSeekTarget = index;

    // Only initiate the next move if not already animating.
    // The completion of the current animation will trigger the next step
    // in _onMoveComplete since _guideSeekTarget is set.
    if (!_animationController.isAnimating) {
      _analysisController.setPlayingInternal(true);
      if (index > currentIndex) {
        handleAnalysisNext(overrideDuration: const Duration(milliseconds: 150));
      } else {
        _analysisController.setRewindingInternal(true);
        handleAnalysisPrevious(
            overrideDuration: const Duration(milliseconds: 150));
      }
    }
    notifyListeners();
  }

  void scramble() {
    if (_animationController.isAnimating) return;

    final newMoves = CubeState.generateScramble(_scrambleLength);
    _moveHistory = newMoves;
    _moveIndex = 0;
    _solutionStartIndex = 0;
    _showingSolution = false;
    _activeDemoStepIndex = null;
    _baseCubeState = CubeState.solved();
    _cubeState = _baseCubeState;
    _isScrambling = true;
    _isScanned = false;

    // Pre-compute the final scrambled state for reset
    _savedState = CubeState.solved().applyMoves(newMoves);

    _analysisController.pause();
    _animationController.setSpeed(const Duration(milliseconds: 400));
    _animationController.queueMoves(newMoves);
    notifyListeners();
  }

  Future<void> solve({
    SolveMethod method = SolveMethod.kociemba,
    bool? showExplanations,
  }) async {
    if (_animationController.isAnimating) return;

    if ((method == SolveMethod.lbl || method == SolveMethod.cfop) &&
        !PremiumManager().canAccessFeature('lbl_solver')) {
      return;
    }

    _activeDemoStepIndex = null;

    if (_cubeState.isSolved &&
        _showingSolution &&
        _moveIndex == _moveHistory.length) {
      return;
    }

    _showExplanations = showExplanations ?? PremiumManager().isPremium;

    final CubeState solveState = _showingSolution
        ? CubeState.solved().applyMoves(_moveHistory.sublist(0, _moveIndex))
        : _cubeState;

    _isSolving = true;
    _cubeState = solveState;
    if (!_showingSolution) {
      _baseCubeState = solveState;
      _moveHistory = [];
      _moveIndex = 0;
    }
    notifyListeners();

    final solveResult = await SolverService.solve(
      state: solveState,
      method: method,
    );

    if (solveResult.moves.isNotEmpty) {
      if (_showingSolution) {
        _moveHistory = [
          ..._moveHistory.sublist(0, _moveIndex),
          ...solveResult.moves
        ];
      } else {
        _moveHistory = solveResult.moves;
        _moveIndex = 0;
      }

      // Stop "solving" (computing) and show interactive playback controls
      _isSolving = false;
      _showingSolution = true;

      _analysisController.loadSolution(
        solveResult.moves,
        _cubeState.clone(),
        solveResult.phase1MoveCount,
        moveStageNames: solveResult.stageNames,
        moveStageDescriptions: solveResult.stageDescriptions,
        moveAlgorithmNames: solveResult.algorithmNames,
      );

      // Do NOT auto-play; let user orient themselves and hit play when ready
      // This applies to both premium and non-premium for a consistent experience
    } else {
      _isSolving = false;
    }
    notifyListeners();
  }

  // Removed startARGuidedSolve

  void performMove(CubeMove move) {
    if (_animationController.isAnimating) return;
    _animationController.setSpeed(const Duration(milliseconds: 400));
    _animationController.queueMoves([move]);
    notifyListeners();
  }

  void updateCubeState(CubeState newState) {
    _cubeState = newState;
    _baseCubeState = newState;
    _savedState = newState;
    _moveHistory = [];
    _moveIndex = 0;
    _solutionStartIndex = 0;
    _showingSolution = false;
    _showExplanations = false;
    _isScanned = true;
    notifyListeners();
  }

  void resetToSaved() {
    if (_savedState == null) return;
    if (_animationController.isAnimating) {
      _animationController.clearQueue();
    }
    _cubeState = _savedState!;
    _baseCubeState = _savedState!;
    _moveHistory = [];
    _moveIndex = 0;
    _solutionStartIndex = 0;
    _showingSolution = false;
    _showExplanations = false;
    _isSolving = false;
    _isScrambling = false;
    _activeDemoStepIndex = null;
    _stickerLabels = null;
    _analysisController.pause();
    _animationController.clearQueue();
    _moveDirectionQueue.clear();
    notifyListeners();
  }

  Future<void> handleDemoRequested(
    int stepIndex,
    CubeState initialState, {
    List<CubeMove>? moves,
    double? initialRotationX,
    double? targetRotationX,
    double? initialRotationY,
    double? targetRotationY,
    String? demoType,
    Map<CubeFace, Map<int, String>>? stickerLabels,
    List<int>? targetPieces,
    List<String?>? moveDescriptions,
  }) async {
    _cubeState = initialState;
    _activeDemoStepIndex = stepIndex;
    _activeDemoType = demoType;
    _stickerLabels = stickerLabels;
    _initialStickerLabels =
        stickerLabels?.map((face, labels) => MapEntry(face, Map.from(labels)));
    _initialCubeState = initialState;

    if (moves == null) {
      _showingSolution = false;
      _moveIndex = 0;
      _solutionStartIndex = 0;
    } else {
      // Initialize camera orientation for the demo
      _rotationX = initialRotationX ?? 0.5;
      _rotationY = initialRotationY ?? 0.75;

      // Update Move History and Analysis Controller to list moves in UI
      _moveHistory = List.from(moves);
      _moveIndex = 0;
      _solutionStartIndex = 0;
      _analysisController.loadSolution(
        moves,
        initialState,
        moves.length,
        moveStageDescriptions: moveDescriptions,
      );
      _showingSolution = true;
      _showExplanations = true;
    }
    notifyListeners();
  }

  void cancelDemo() {
    final capturedStepIndex = _activeDemoStepIndex;
    final capturedDemoType = _activeDemoType;
    _showingSolution = false;
    _activeDemoStepIndex = null;
    _activeDemoType = null;
    _stickerLabels = null;
    _animationController.setSpeed(const Duration(milliseconds: 400));
    _animationController.clearQueue();
    _moveDirectionQueue.clear();
    notifyListeners();
    onDemoFinished?.call(capturedStepIndex, capturedDemoType);
  }

  @override
  void dispose() {
    PremiumManager().removeListener(_onPremiumChanged);
    _animationController.dispose();
    _analysisController.dispose();
    super.dispose();
  }
}
