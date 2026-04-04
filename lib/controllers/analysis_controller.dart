import 'package:flutter/foundation.dart';
import '../models/cube_state.dart';
import '../models/cube_move.dart';

/// Controls solution analysis playback with auto-play, speed control,
/// and move navigation.
class AnalysisController extends ChangeNotifier {
  List<CubeMove> _solution = [];
  List<CubeState> _states = []; // Cached states for each step
  List<String?> _moveStageNames = [];
  List<String?> _moveStageDescriptions = [];
  List<String?> _moveAlgorithmNames = [];
  int _currentIndex = 0;
  int? _animatingIndex;
  String? _stageName;
  int _phase1MoveCount = 0;
  bool _isPlaying = false;
  bool _isFastForwarding = false;
  double _speed = 1.0; // 0.5x, 1x, 2x

  final void Function(int index)? onMoveChanged;
  bool _isRewinding = false;

  // Callbacks for main state to handle the actual logic
  void Function()? onPlayRequest;
  void Function()? onRewindRequest;
  void Function()? onPauseRequest;
  void Function()? onNextRequest;
  void Function()? onPreviousRequest;
  void Function(int index, {bool immediate})? onSeekRequest;

  AnalysisController({
    this.onMoveChanged,
    this.onPlayRequest,
    this.onRewindRequest,
    this.onPauseRequest,
    this.onNextRequest,
    this.onPreviousRequest,
    this.onSeekRequest,
  });

  // Getters
  List<CubeMove> get solution => _solution;
  List<CubeState> get states => _states;
  List<String?> get moveStageNames => _moveStageNames;
  List<String?> get moveStageDescriptions => _moveStageDescriptions;
  List<String?> get moveAlgorithmNames => _moveAlgorithmNames;
  int get currentIndex => _currentIndex;
  int? get animatingIndex => _animatingIndex;
  bool get isPlaying => _isPlaying;
  bool get isRewinding => _isRewinding;
  bool get isFastForwarding => _isFastForwarding;
  double get speed => _speed;
  CubeMove? get currentMove =>
      (_currentIndex > 0 && _currentIndex <= _solution.length)
          ? _solution[_currentIndex - 1]
          : null;
  bool get hasNext => _currentIndex < _solution.length;
  bool get hasPrevious => _currentIndex > 0;
  bool get isComplete => _currentIndex >= _solution.length;
  int get phase1MoveCount => _phase1MoveCount;
  String? get stageName => _stageName;

  /// Returns 1 if current move is in Phase 1, 2 if in Phase 2
  int get currentPhase => _currentIndex <= _phase1MoveCount ? 1 : 2;

  /// Load a new solution and calculate states
  void loadSolution(
    List<CubeMove> solution,
    CubeState initialState,
    int phase1MoveCount, {
    List<String?>? moveStageNames,
    List<String?>? moveStageDescriptions,
    List<String?>? moveAlgorithmNames,
  }) {
    _solution = solution;
    _phase1MoveCount = phase1MoveCount;
    _moveStageNames = moveStageNames ?? List.filled(solution.length, null);
    _moveStageDescriptions =
        moveStageDescriptions ?? List.filled(solution.length, null);
    _moveAlgorithmNames =
        moveAlgorithmNames ?? List.filled(solution.length, null);
    _currentIndex = 0;
    _isPlaying = false;
    _isRewinding = false;
    _isFastForwarding = false;
    _stageName = null;

    // Pre-calculate states for each step for explanation generation
    _states = [initialState];
    CubeState currentState = initialState;
    for (final move in solution) {
      currentState = currentState.applyMove(move);
      _states.add(currentState);
    }

    notifyListeners();
  }

  /// Update index without triggering requests (used by main state after move completes)
  void updateIndexInternal(int index) {
    if (index < 0 || index > _solution.length) return;
    _currentIndex = index;
    _stageName = (index > 0 && index <= _moveStageNames.length)
        ? _moveStageNames[index - 1]
        : null;
    notifyListeners();
  }

  /// Set playing state internally
  /// Set playing state internally
  void setPlayingInternal(bool playing) {
    _isPlaying = playing;
    if (!playing) {
      _isRewinding = false;
      _isFastForwarding = false;
    }
    notifyListeners();
  }

  /// Set animating index internally (used by main state while move is in progress)
  void setAnimatingIndexInternal(int? index) {
    if (index != null && (index < 0 || index > _solution.length)) return;
    _animatingIndex = index;
    notifyListeners();
  }

  /// Set rewinding state internally
  void setRewindingInternal(bool rewinding) {
    _isRewinding = rewinding;
    if (rewinding) {
      _isPlaying = true;
      _isFastForwarding = false;
    }
    notifyListeners();
  }

  /// Set fast-forwarding state internally
  void setFastForwardingInternal(bool fast) {
    _isFastForwarding = fast;
    if (fast) {
      _isPlaying = true;
      _isRewinding = false;
    }
    notifyListeners();
  }

  /// Request auto-play
  void play({bool fast = false}) {
    if (isComplete) return;
    _isPlaying = true;
    _isRewinding = false;
    _isFastForwarding = fast;
    notifyListeners();
    onPlayRequest?.call();
  }

  /// Request auto-rewind (always 2x)
  void rewind() {
    if (!hasPrevious) return;
    _isPlaying = true;
    _isRewinding = true;
    _isFastForwarding = true; // For speed 2x
    notifyListeners();
    onRewindRequest?.call();
  }

  /// Request pause
  void pause() {
    _isPlaying = false;
    _isRewinding = false;
    _isFastForwarding = false;
    onPauseRequest?.call();
  }

  /// Toggle play/pause
  void togglePlayPause() {
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }

  /// Set playback speed
  void setSpeed(double speed) {
    _speed = speed;
    notifyListeners();
  }

  /// Request next move
  void nextMove() {
    if (!hasNext) return;
    onNextRequest?.call();
  }

  /// Request previous move
  void previousMove() {
    if (!hasPrevious) return;
    onPreviousRequest?.call();
  }

  /// Request jump to specific move index
  void goToMove(int index, {bool immediate = false}) {
    if (index < 0 || index > _solution.length) return;
    onSeekRequest?.call(index, immediate: immediate);
  }

  /// Request immediate jump to specific move index (no animation)
  void jumpToMove(int index) {
    goToMove(index, immediate: true);
  }

  /// Reset to beginning
  void reset({bool immediate = true}) {
    goToMove(0, immediate: immediate);
  }
}
