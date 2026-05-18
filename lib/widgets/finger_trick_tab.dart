import 'package:flutter/material.dart';
import '../models/finger_trick.dart';
import '../models/trigger_library.dart';
import '../models/cube_state.dart';

import '../animation/cube_animation_controller.dart';
import 'cube_renderer.dart';

class FingerTrickTab extends StatefulWidget {
  final String? initialTrickId;

  const FingerTrickTab({super.key, this.initialTrickId});

  @override
  State<FingerTrickTab> createState() => _FingerTrickTabState();
}

class _FingerTrickTabState extends State<FingerTrickTab>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late List<FingerTrick> _tricks;
  late List<CubeAnimationController> _animControllers;
  late List<CubeState> _cubeStates;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tricks = TriggerLibrary.all;
    if (widget.initialTrickId != null) {
      _currentIndex = _tricks.indexWhere((t) => t.id == widget.initialTrickId);
      if (_currentIndex == -1) _currentIndex = 0;
    }
    _pageController = PageController(initialPage: _currentIndex);

    _animControllers = List.generate(
      _tricks.length,
      (i) => CubeAnimationController(
        vsync: this,
        moveDuration: const Duration(milliseconds: 500),
        onUpdate: () => setState(() {}),
        onMoveComplete: () {
          final controller = _animControllers[i];
          if (controller.currentMove != null) {
            setState(() {
              _cubeStates[i] = _cubeStates[i].applyMove(controller.currentMove!);
            });
          }
          // Loop animation if playing
          if (!controller.isAnimating && _isPlaying) {
            _playTrigger(i);
          }
        },
      ),
    );

    _cubeStates = List.generate(
      _tricks.length,
      (i) => CubeState.solved(),
    );
  }

  bool _isPlaying = false;

  void _playTrigger(int index) {
    final trick = _tricks[index];
    final controller = _animControllers[index];
    
    // Reset to solved if we've reached the end or just starting
    setState(() {
      _cubeStates[index] = CubeState.solved();
    });

    controller.queueMoves(trick.moves);
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _playTrigger(_currentIndex);
      } else {
        _animControllers[_currentIndex].clearQueue();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _animControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0D1A),
      child: Column(
        children: [
          // Trick Selector (Horizontal List)
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tricks.length,
              itemBuilder: (context, index) {
                final isSelected = index == _currentIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_tricks[index].name),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    selectedColor: const Color(0xFF6366F1),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _animControllers[_currentIndex].clearQueue();
                  _currentIndex = index;
                  _isPlaying = false;
                  _cubeStates[_currentIndex] = CubeState.solved();
                });
              },
              itemCount: _tricks.length,
              itemBuilder: (context, index) {
                return _buildTrickPage(_tricks[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrickPage(FingerTrick trick, int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cube Demo Section
          Center(
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Center(
                    child: CustomPaint(
                      painter: CubeRenderer(
                        cubeState: _cubeStates[index],
                        animatingMove: _animControllers[index].currentMove,
                        animationProgress: _animControllers[index].progress,
                        rotationX: 0.4,
                        rotationY: 0.6,
                      ),
                      size: const Size(200, 200),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: FloatingActionButton.small(
                      onPressed: _togglePlay,
                      backgroundColor: const Color(0xFF6366F1),
                      child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        trick.algorithm,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Details Section
          Text(
            trick.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            trick.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Finger Trick Explanation
          const Text(
            'HOW TO PERFORM',
            style: TextStyle(
              color: Color(0xFF6366F1),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          if (trick.stepExplanations != null)
            ...trick.stepExplanations!.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            

        ],
      ),
    );
  }
}
