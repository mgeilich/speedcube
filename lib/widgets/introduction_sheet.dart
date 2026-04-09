import 'package:flutter/material.dart';
import 'cube_renderer.dart';
import '../models/cube_state.dart';
import '../models/cube_move.dart';
import '../animation/cube_animation_controller.dart';
import '../utils/move_explainer.dart';

class IntroductionSheet extends StatefulWidget {
  const IntroductionSheet({super.key});

  @override
  State<IntroductionSheet> createState() => _IntroductionSheetState();
}

class _IntroductionSheetState extends State<IntroductionSheet>
    with TickerProviderStateMixin {
  late CubeState _introCubeState;
  late CubeAnimationController _introAnimationController;
  bool _introShowLabels = true;
  String _introMoveDescription =
      "Press a button below to see how the cube moves.";

  @override
  void initState() {
    super.initState();
    // Introduction state
    _introCubeState =
        CubeState.solved().applyMoves(CubeState.generateScramble(20));
    _introAnimationController = CubeAnimationController(
      vsync: this,
      moveDuration: const Duration(milliseconds: 300),
      onUpdate: () => setState(() {}),
      onMoveComplete: () {
        if (_introAnimationController.currentMove != null) {
          setState(() {
            _introCubeState = _introCubeState
                .applyMove(_introAnimationController.currentMove!);
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _introAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 24),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Fixed header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.info_outline,
                        color: Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Introduction: The Cube',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white38, size: 26),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                child: _buildIntroductionBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroductionBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Before diving into algorithms, let\'s understand how the cube moves. '
          'The cube consists of 6 faces: Up (U), Down (D), Front (F), Back (B), Left (L), and Right (R). '
          'Each face consists of 1 center sticker, 4 edge stickers, and 4 corner stickers. '
          'Advanced methods like Roux also use the **Middle (M)**, **Equatorial (E)**, and **Standing (S)** slices, as well as **Wide moves** (moving two layers at once).',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 15,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: Center(
            child: CustomPaint(
              painter: CubeRenderer(
                cubeState: _introCubeState,
                animatingMove: _introAnimationController.currentMove,
                animationProgress: _introAnimationController.progress,
                rotationX: -0.5,
                rotationY: 0.75,
                stickerLabels: _introShowLabels
                    ? {
                        CubeFace.u: {
                          4: 'TOP',
                        },
                        CubeFace.f: {
                          4: 'FRONT',
                          1: 'EDGE',
                          7: 'EDGE',
                          3: 'EDGE',
                          5: 'EDGE',
                          0: 'CORNER',
                          2: 'CORNER',
                          6: 'CORNER',
                          8: 'CORNER',
                        }
                      }
                    : null,
              ),
              size: const Size(180, 180),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _introMoveDescription,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildIntroMoveButton('R'),
            _buildIntroMoveButton('R\''),
            _buildIntroMoveButton('R2'),
            _buildIntroMoveButton('L'),
            _buildIntroMoveButton('L\''),
            _buildIntroMoveButton('L2'),
            _buildIntroMoveButton('U'),
            _buildIntroMoveButton('U\''),
            _buildIntroMoveButton('U2'),
            _buildIntroMoveButton('D'),
            _buildIntroMoveButton('D\''),
            _buildIntroMoveButton('D2'),
            _buildIntroMoveButton('F'),
            _buildIntroMoveButton('F\''),
            _buildIntroMoveButton('F2'),
            _buildIntroMoveButton('B'),
            _buildIntroMoveButton('B\''),
            _buildIntroMoveButton('B2'),
            const SizedBox(width: double.infinity, child: Divider(color: Colors.white10, height: 24)),
            _buildIntroMoveButton('M'),
            _buildIntroMoveButton('M\''),
            _buildIntroMoveButton('M2'),
            _buildIntroMoveButton('E'),
            _buildIntroMoveButton('S'),
            const SizedBox(width: double.infinity, child: Divider(color: Colors.white10, height: 24)),
            _buildIntroMoveButton('Rw'),
            _buildIntroMoveButton('Lw'),
            _buildIntroMoveButton('Uw'),
            _buildIntroMoveButton('Dw'),
            _buildIntroMoveButton('Fw'),
            _buildIntroMoveButton('Bw'),
          ],
        ),
      ],
    );
  }

  Widget _buildIntroMoveButton(String notation) {
    return ActionChip(
      label: Text(
        notation,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      side: const BorderSide(color: Colors.white24),
      onPressed: () {
        if (_introAnimationController.isAnimating) return;
        final move = CubeMove.parse(notation);
        if (move != null) {
          setState(() {
            _introShowLabels = false;
            _introMoveDescription = MoveExplainer.getDescription(move);
          });
          _introAnimationController.queueMoves([move]);
        }
      },
    );
  }
}
