import 'package:flutter/material.dart';
import '../models/cube_move.dart';

/// Controls the animation of cube moves
class CubeAnimationController {
  final TickerProvider vsync;
  final Duration moveDuration;
  final VoidCallback onUpdate;
  final VoidCallback? onMoveComplete;

  late AnimationController _controller;
  final List<CubeMove> _moveQueue = [];
  CubeMove? _currentMove;
  bool _isAnimating = false;

  CubeAnimationController({
    required this.vsync,
    this.moveDuration = const Duration(milliseconds: 250),
    required this.onUpdate,
    this.onMoveComplete,
  }) {
    _controller = AnimationController(
      vsync: vsync,
      duration: moveDuration,
    );
    _controller.addListener(onUpdate);
    _controller.addStatusListener(_onAnimationStatus);
  }

  /// Current move being animated
  CubeMove? get currentMove => _currentMove;

  /// Animation progress (0.0 to 1.0)
  double get progress => _controller.value;

  /// Whether animation is currently running
  bool get isAnimating => _isAnimating;

  /// Number of moves remaining in the queue
  int get queueLength => _moveQueue.length + (_currentMove != null ? 1 : 0);

  /// Add moves to the animation queue
  void queueMoves(List<CubeMove> moves) {
    _moveQueue.addAll(moves);
    if (!_isAnimating) {
      _startNextMove();
    }
  }

  /// Clear all queued moves and stop animation
  void clearQueue() {
    _moveQueue.clear();
    if (_isAnimating || _controller.isAnimating) {
      _controller.stop();
      _isAnimating = false;
      _currentMove = null;
    }
  }

  /// Set animation speed
  void setSpeed(Duration duration) {
    _controller.duration = duration;
  }

  void _startNextMove() {
    if (_moveQueue.isEmpty) {
      _isAnimating = false;
      _currentMove = null;
      return;
    }

    _isAnimating = true;
    _currentMove = _moveQueue.removeAt(0);
    _controller.forward(from: 0.0);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      onMoveComplete?.call();
      _startNextMove();
    }
  }

  void dispose() {
    _controller.dispose();
  }
}
