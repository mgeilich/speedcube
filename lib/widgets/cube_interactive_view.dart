import 'package:flutter/material.dart';
import '../models/cube_state.dart';
import '../models/cube_move.dart';
import 'cube_renderer.dart';


class CubeInteractiveView extends StatelessWidget {
  final CubeState cubeState;
  final double rotationX;
  final double rotationY;
  final CubeMove? animatingMove;
  final double animationProgress;
  final Map<CubeFace, Map<int, String>>? stickerLabels;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final VoidCallback? onExit;
  final bool showingSolution;


  const CubeInteractiveView({
    super.key,
    required this.cubeState,
    required this.rotationX,
    required this.rotationY,
    required this.animatingMove,
    required this.animationProgress,
    this.stickerLabels,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    this.onExit,
    this.showingSolution = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        SizedBox(
          height: 320,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanStart: onPanStart,
                onPanUpdate: onPanUpdate,
                onPanEnd: onPanEnd,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFF1E1E2E),
                        Color(0xFF0F0F1A),
                      ],
                      radius: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // 3D Cube
                        CustomPaint(
                          painter: CubeRenderer(
                            cubeState: cubeState,
                            rotationX: rotationX,
                            rotationY: rotationY,
                            animatingMove: animatingMove,
                            animationProgress: animationProgress,
                            highlightedFace: null,
                            highlightedStickers: null,
                            availableStickers: null,
                            stickerLabels: stickerLabels,
                            dimNonHighlighted: false,
                          ),
                          size: Size.infinite,
                        ),


                        // Exit Button (Prominent X in top right)
                        if (showingSolution && onExit != null)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: onExit,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
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
        ),
      ],
    );
  }


}
