import 'package:flutter/material.dart';
import 'cube_renderer.dart';
import '../models/cube_state.dart';
import '../models/cube_move.dart';
// Unused imports removed

class DemoOption {
  final String label;
  final VoidCallback onTap;

  const DemoOption({required this.label, required this.onTap});
}

/// Interactive guide for the Layer-by-Layer method.
class LayerByLayerGuideSheet extends StatefulWidget {
  final int initialExpandedStepIndex;
  final void Function(
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
  })? onDemoRequested;
  final VoidCallback? onKociembaRequested;
  final void Function(int index)? onTabChanged;

  const LayerByLayerGuideSheet({
    super.key,
    this.initialExpandedStepIndex = -1,
    this.onDemoRequested,
    this.onKociembaRequested,
    this.onTabChanged,
  });

  @override
  State<LayerByLayerGuideSheet> createState() => _LayerByLayerGuideSheetState();
}

class _LayerByLayerGuideSheetState extends State<LayerByLayerGuideSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: widget.initialExpandedStepIndex != -1
          ? widget.initialExpandedStepIndex
          : 0,
    );
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    widget.onTabChanged?.call(_tabController.index);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
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
                    child: const Icon(Icons.school, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Layer-by-Layer Guide',
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                  tabs: const [
                    _TutorialTab(step: 1, label: 'CROSS'),
                    _TutorialTab(step: 2, label: '1ST LAYER'),
                    _TutorialTab(step: 3, label: '2ND LAYER'),
                    _TutorialTab(step: 4, label: 'Y-CROSS'),
                    _TutorialTab(step: 5, label: 'Y-CORNERS'),
                    _TutorialTab(step: 6, label: 'LAST LAYER'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabPage(_buildStep1Body()),
                  _buildTabPage(_buildStep2Body()),
                  _buildTabPage(_buildStep3Body()),
                  _buildTabPage(_buildStep4Body()),
                  _buildTabPage(_buildStep5Body()),
                  _buildTabPage(_buildStep6Body()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPage(Widget body) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: body,
    );
  }


  Widget _buildStep1Body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text(
                'Create a white cross on the TOP face, ensuring the side colors of the cross edges match the center pieces.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: CustomPaint(
                painter: CubeRenderer(
                  cubeState: _getCrossTargetState(),
                  rotationX: 0.5,
                  rotationY: 0.6,
                  highlightedStickers: _getCrossHighlights(),
                ),
                size: const Size(110, 110),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'How To',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Hold the cube with the center white piece on top. Find a white edge (not corner) piece and bring it to the bottom layer. Align its non-white color with the matching center piece by rotating the bottom face. If the white face is on the bottom, rotate the face 180 degrees to bring it to the top. If the white is on the side, position it under the matching center, then execute F\', U\', R, U to move it to the top.',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        _buildDemoButtons(
          [
            DemoOption(
              label: 'Show White on Bottom',
              onTap: () {
                final state = _getCrossDemoStateBottom();
                widget.onDemoRequested?.call(
                  0, // Step 1
                  state,
                  moves: [CubeMove.dPrime, CubeMove.f2],
                  initialRotationX: -0.8,
                );
              },
            ),
            DemoOption(
              label: 'Show White on Side',
              onTap: () {
                final state = _getCrossDemoStateSide();
                widget.onDemoRequested?.call(
                  0, // Step 1
                  state,
                  moves: [
                    CubeMove.d2,
                    CubeMove.fPrime,
                    CubeMove.uPrime,
                    CubeMove.r,
                    CubeMove.u,
                  ], // Sequence: Turn bottom x2 (position under Front), turn front (to side), move top (slot to side), bring up (insert), restore top
                  initialRotationX: -0.8,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2Body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: const Text(
                'Flip the cube over so the white cross is on the bottom. Then, insert the four white corner pieces into their correct spots. Once done, the entire first layer (white face and the "T" on sides) is solved.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: CustomPaint(
                painter: CubeRenderer(
                  cubeState: _getFirstLayerTargetState(),
                  rotationX: -0.6,
                  rotationY: 0.6,
                  highlightedStickers: [
                    const MapEntry(CubeFace.f, 8),
                    const MapEntry(CubeFace.r, 6),
                    const MapEntry(CubeFace.d, 2),
                  ],
                ),
                size: const Size(110, 110),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'How To',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'For every white corner on the top layer, rotate the top layer until it is above its target corner. Keep repeating this 4-move sequence until the piece is moved to the bottom corner. If a bottom corner is white, but doesn\'t match the center color or is rotated, use the same 4-move sequence to push it back to the top and rotate the top.',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        _buildAlgorithmText('R U R\' U\''),
        _buildDemoButtons(
          [
            DemoOption(
              label: 'Show Corner Insertion',
              onTap: () {
                widget.onDemoRequested?.call(
                  1, // Step 2
                  _getFirstLayerDemoStateFront(),
                  moves: [
                    // 5x
                    CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime,
                    CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime,
                    CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime,
                    CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime,
                    CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime,
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3Body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: const Text(
                'Solve the middle layer edges to complete the first two layers (F2L).',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: CustomPaint(
                painter: CubeRenderer(
                  cubeState: _getSecondLayerTargetState(),
                  rotationX: -0.6,
                  rotationY: 0.6,
                ),
                size: const Size(110, 110),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'How To',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Find an edge on the top layer that doesn\'t have yellow. Rotate the top layer until the front-facing color matches the center color. If the top-facing color matches the center to the right, use the "Edge to Right" sequence. If it matches the center to the left, use the "Edge to Left" sequence.',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline,
                  color: Colors.orangeAccent, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Stuck? If a piece is trapped in the middle layer or flipped upside down, perform either algorithm below to insert a yellow edge. This will push the trapped piece back out to the top!',
                  style: TextStyle(
                      color: Colors.orangeAccent, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildIllustration(
          'Edge to the Right',
          'If the edge\'s top color matches the center to the right:',
          _getF2LDemoRightState(),
          highlightedStickers: [
            const MapEntry(CubeFace.u, 7),
            const MapEntry(CubeFace.f, 1),
          ],
        ),
        _buildAlgorithmText('U R U\' R\' U\' F\' U F'),
        const SizedBox(height: 20),
        _buildDemoButtons(
          [
            DemoOption(
              label: 'Show Right Insertion',
              onTap: () {
                widget.onDemoRequested?.call(
                  2, // Step 3
                  _getF2LDemoRightState(),
                  moves: [
                    CubeMove.u,
                    CubeMove.r,
                    CubeMove.uPrime,
                    CubeMove.rPrime,
                    CubeMove.uPrime,
                    CubeMove.fPrime,
                    CubeMove.u,
                    CubeMove.f
                  ],
                  initialRotationX: 0.5,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildIllustration(
          'Edge to the Left',
          'If the edge\'s top color matches the center to the left:',
          _getF2LDemoLeftState(),
          highlightedStickers: [
            const MapEntry(CubeFace.u, 7),
            const MapEntry(CubeFace.f, 1),
          ],
        ),
        _buildAlgorithmText('U\' L\' U L U F U\' F\''),
        _buildDemoButtons(
          [
            DemoOption(
              label: 'Show Left Insertion',
              onTap: () {
                widget.onDemoRequested?.call(
                  2, // Step 3
                  _getF2LDemoLeftState(),
                  moves: [
                    CubeMove.uPrime,
                    CubeMove.lPrime,
                    CubeMove.u,
                    CubeMove.l,
                    CubeMove.u,
                    CubeMove.f,
                    CubeMove.uPrime,
                    CubeMove.fPrime
                  ],
                  initialRotationX: 0.5,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep4Body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: const Text(
                'Orient the last layer to create a yellow cross on top.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: CustomPaint(
                painter: CubeRenderer(
                  cubeState: _getYellowCrossTargetState(),
                  rotationX: 0.5,
                  rotationY: 0.6,
                ),
                size: const Size(110, 110),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'How To',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Execute the following algorithm repeatedly until you have a yellow cross on top:',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        _buildAlgorithmText('F R U R\' U\' F\''),
        const SizedBox(height: 12),
        const Text(
          'If you have two adjacent yellow edges on top, hold the cube so they point to the BACK and LEFT (like a backwards L) and do the algorithm. If two opposite edges are yellow, hold the cube so the line is HORIZONTAL across the middle, and do the algorithm.',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        _buildDemoButtons([
          DemoOption(
            label: 'Show Full Cross Sequence',
            onTap: () {
              widget.onDemoRequested?.call(
                3, // Step 4
                _getStep4DotState(),
                moves: [
                  // 1. Dot to Angle
                  CubeMove.f, CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime, CubeMove.fPrime,
                  // Reorient Angle to Back-Left (U2 moves the Angle from Front-Right to Back-Left)
                  CubeMove.u2,
                  // 2. Angle to Line (Results in a horizontal line across UL and UR)
                  CubeMove.f, CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime, CubeMove.fPrime,
                  // 3. Line to Cross
                  CubeMove.f, CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime, CubeMove.fPrime,
                ],
                initialRotationX: 0.5,
              );
            },
          ),
        ]),
      ],
    );
  }

  Widget _buildStep5Body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: const Text(
                'Complete the yellow face by orienting the final corners.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: CustomPaint(
                painter: CubeRenderer(
                  cubeState: _getYellowFaceTargetState(),
                  rotationX: 0.5,
                  rotationY: 0.6,
                ),
                size: const Size(110, 110),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'How To',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Execute the following algorithm repeatedly until your yellow top face is completely solved. This algorithm is called "Sune".',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        _buildAlgorithmText('R U R\' U R U2 R\''),
        const SizedBox(height: 12),
        const Text(
          'Count how many yellow corner stickers are on the top face:',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '• If exactly 1 corner is yellow: Rotate the top layer until that corner is in the FRONT-LEFT position.\n'
          '• If 0 or 2 corners are yellow: Rotate the top layer until you see a yellow sticker on the LEFT face (facing left) of the front-left corner.',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        _buildDemoButtons([
          DemoOption(
            label: 'Show Sune Algorithm',
            onTap: () {
              widget.onDemoRequested?.call(
                4, // Step 5 (0-based index)
                _getSuneDemoState(),
                moves: [
                  CubeMove.r,
                  CubeMove.u,
                  CubeMove.rPrime,
                  CubeMove.u,
                  CubeMove.r,
                  CubeMove.u2,
                  CubeMove.rPrime
                ],
                initialRotationX: 0.5,
              );
            },
          ),
        ]),
      ],
    );
  }

  Widget _buildStep6Body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: const Text(
                'Permute the last layer pieces to fully solve the cube!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: CustomPaint(
                painter: CubeRenderer(
                  cubeState: _getSolvedTargetState(),
                  rotationX: 0.5,
                  rotationY: 0.6,
                ),
                size: const Size(110, 110),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          '1. Solve Corners',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'First, look for "Headlights"—two corners on the same face with matching side colors. \n\n'
          '• If you find them: Rotate the top layer to put them on the BACK face, then do the algorithm.\n'
          '• If you have none: Do the algorithm once from any angle to get headlights.',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        _buildAlgorithmText('R\' F R\' B2 R F\' R\' B2 R2'),
        const SizedBox(height: 12),
        _buildDemoButtons([
          DemoOption(
            label: 'Show Corner Algorithm',
            onTap: () {
              widget.onDemoRequested?.call(
                5, // Step 6
                _getCornerPermutationDemoState(),
                moves: [
                  CubeMove.rPrime,
                  CubeMove.f,
                  CubeMove.rPrime,
                  CubeMove.b2,
                  CubeMove.r,
                  CubeMove.fPrime,
                  CubeMove.rPrime,
                  CubeMove.b2,
                  CubeMove.r2
                ],
                initialRotationX: 0.5,
              );
            },
          ),
        ]),
        const SizedBox(height: 32),
        const Text(
          '2. Solve Edges',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Now that corners are solved, just the edges remain. Look for a completely solved side and put it on the BACK. (If no sides are solved, do the algorithm once from any angle.)',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Clockwise Cycle:',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        _buildAlgorithmText('R2 U R U R\' U\' R\' U\' R\' U R\''),
        const Text(
          'Counter-Clockwise Cycle:',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        _buildAlgorithmText('R U\' R U R U R U\' R\' U\' R2'),
        const SizedBox(height: 12),
        _buildDemoButtons([
          DemoOption(
            label: 'Show Edge Cycle',
            onTap: () {
              widget.onDemoRequested?.call(
                5, // Step 6
                _getEdgeCycleDemoState(),
                moves: [
                  CubeMove.r2,
                  CubeMove.u,
                  CubeMove.r,
                  CubeMove.u,
                  CubeMove.rPrime,
                  CubeMove.uPrime,
                  CubeMove.rPrime,
                  CubeMove.uPrime,
                  CubeMove.rPrime,
                  CubeMove.u,
                  CubeMove.rPrime
                ],
                initialRotationX: 0.5,
              );
            },
          ),
        ]),
      ],
    );
  }

  Widget _buildIllustration(
    String title,
    String description,
    CubeState cubeState, {
    List<MapEntry<CubeFace, int>>? highlightedStickers,
    double rotationX = -0.4,
    double rotationY = 0.6,
    bool dimmable = false, // added parameter to silence lint
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                description,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: CustomPaint(
                painter: CubeRenderer(
                  cubeState: cubeState,
                  rotationX: rotationX,
                  rotationY: rotationY,
                  highlightedStickers: highlightedStickers,
                  dimNonHighlighted: dimmable && highlightedStickers != null,
                ),
                size: const Size(110, 110),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDemoButtons(List<DemoOption> demoOptions) {
    if (demoOptions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        ...demoOptions.map((option) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildShowMeButton(
                label: option.label,
                color: const Color(
                    0xFF6366F1), // Default accent color or accept as param
                onPressed: option.onTap,
              ),
            )),
      ],
    );
  }

  Widget _buildAlgorithmText(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.code, color: Colors.white38, size: 18),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 16,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowMeButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_fill, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step State Generators ──────────────────────────────────────────────────

  CubeState _getWhiteOnBottomState() {
    final state = CubeState.solved();
    // Putting White on bottom while keeping Side Centers standard (Green=Front)
    // swaps U(White) and D(Yellow) global stickering.
    for (int i = 0; i < 9; i++) {
      state.u[i] = CubeColor.yellow;
      state.d[i] = CubeColor.white;
    }
    return state;
  }

  CubeState _getSecondLayerTargetState() {
    final state = _getWhiteOnBottomState();
    // Mess up the top layer to avoid looking fully "solved"
    // 1. Swap UF (U7, F1) and UB (U1, B1) edges
    _swapEdges(
        state, CubeFace.u, 7, CubeFace.f, 1, CubeFace.u, 1, CubeFace.b, 1);
    // 2. Swap UFR (U8, F2, R0) and UBL (U0, B2, L0) corners
    _swapCorners(state, CubeFace.u, 8, CubeFace.f, 2, CubeFace.r, 0, CubeFace.u,
        0, CubeFace.b, 2, CubeFace.l, 0);
    return state;
  }

  CubeState _getFirstLayerTargetState() {
    // Starts with White solved on bottom.
    // To make it look like only Step 2 is complete (not Step 3),
    // we need to scramble the middle layer (F2L edges) while keeping the bottom.
    // These sequences (inverse F2L) swap middle edges with top edges.
    return _getWhiteOnBottomState().applyMoves([
      // Scramble FR edge
      CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime, CubeMove.fPrime,
      CubeMove.uPrime, CubeMove.f,
      // Scramble FL edge
      CubeMove.lPrime, CubeMove.uPrime, CubeMove.l, CubeMove.u, CubeMove.f,
      CubeMove.u, CubeMove.fPrime,
      // Random U moves to jumble further
      CubeMove.u2, CubeMove.u,
    ]);
  }

  CubeState _getYellowCrossTargetState() {
    final state = _getWhiteOnBottomState();
    // Cross edges (1, 3, 5, 7) are already yellow in _getWhiteOnBottomState.
    // Make corners NOT yellow on top face to show it's "just a cross".
    state.u[0] = CubeColor.blue;
    state.u[2] = CubeColor.red;
    state.u[6] = CubeColor.orange;
    state.u[8] = CubeColor.green;
    return state;
  }

  CubeState _getStep4DotState() {
    final state = _getWhiteOnBottomState();
    // A "dot" state: only the center yellow sticker (U4) is oriented on the top face.
    // Edge stickers are 1 (UB), 3 (UL), 5 (UR), 7 (UF).
    // We flip all 4 edges so their yellow sticker is on the side, not the top face.

    // UB Edge (U1, B1)
    state.u[1] = CubeColor.blue;
    state.b[1] = CubeColor.yellow;
    // UL Edge (U3, L1)
    state.u[3] = CubeColor.orange;
    state.l[1] = CubeColor.yellow;
    // UR Edge (U5, R1)
    state.u[5] = CubeColor.red;
    state.r[1] = CubeColor.yellow;
    // UF Edge (U7, F1)
    state.u[7] = CubeColor.green;
    state.f[1] = CubeColor.yellow;

    // Optional: Mess up the corners so they don't appear yellow on top
    state.u[0] = CubeColor.blue;
    state.u[2] = CubeColor.red;
    state.u[6] = CubeColor.orange;
    state.u[8] = CubeColor.green;

    return state;
  }

  CubeState _getCrossTargetState() {
    // 1. Scramble
    var state = CubeState.solved().applyMoves(CubeState.generateScramble(20));

    // 2. Fix the centers
    state.u[4] = CubeColor.white;
    state.d[4] = CubeColor.yellow;
    state.f[4] = CubeColor.green;
    state.b[4] = CubeColor.blue;
    state.r[4] = CubeColor.red;
    state.l[4] = CubeColor.orange;

    // 3. Fix the cross edges
    // White-Green (U7, F1)
    state.u[7] = CubeColor.white;
    state.f[1] = CubeColor.green;
    // White-Blue (U1, B1)
    state.u[1] = CubeColor.white;
    state.b[1] = CubeColor.blue;
    // White-Red (U5, R1)
    state.u[5] = CubeColor.white;
    state.r[1] = CubeColor.red;
    // White-Orange (U3, L1)
    state.u[3] = CubeColor.white;
    state.l[1] = CubeColor.orange;

    // 4. Ensure corners on U face are NOT white to avoid looking fully solved
    for (int i in [0, 2, 6, 8]) {
      if (state.u[i] == CubeColor.white) {
        state.u[i] = CubeColor.yellow;
      }
    }

    return state;
  }

  List<MapEntry<CubeFace, int>> _getCrossHighlights() {
    return [
      const MapEntry(CubeFace.u, 1),
      const MapEntry(CubeFace.u, 3),
      const MapEntry(CubeFace.u, 4),
      const MapEntry(CubeFace.u, 5),
      const MapEntry(CubeFace.u, 7),
      const MapEntry(CubeFace.f, 1),
      const MapEntry(CubeFace.f, 4),
      const MapEntry(CubeFace.r, 1),
      const MapEntry(CubeFace.r, 4),
      const MapEntry(CubeFace.l, 1),
      const MapEntry(CubeFace.l, 4),
      const MapEntry(CubeFace.b, 1),
      const MapEntry(CubeFace.b, 4),
    ];
  }

  CubeState _getFirstLayerDemoStateFront() {
    // White faces front.
    // Setup: Apply R U R' U' once to a solved cube.
    return _getWhiteOnBottomState().applyMoves([
      CubeMove.r,
      CubeMove.u,
      CubeMove.rPrime,
      CubeMove.uPrime,
    ]);
  }

  CubeState _getF2LDemoRightState() {
    // Generate the exact state so that U R U' R' U' F' U F inserts the edge perfectly.
    // Apply the inverse of the insertion algorithm to the solved F2L.
    // Inverse: F' U' F U R U R' U'
    return _getWhiteOnBottomState().applyMoves([
      CubeMove.fPrime,
      CubeMove.uPrime,
      CubeMove.f,
      CubeMove.u,
      CubeMove.r,
      CubeMove.u,
      CubeMove.rPrime,
      CubeMove.uPrime,
    ]);
  }

  CubeState _getF2LDemoLeftState() {
    // Inverse of U' L' U L U F U' F'
    // is F U F' U' L' U' L U
    return _getWhiteOnBottomState().applyMoves([
      CubeMove.f,
      CubeMove.u,
      CubeMove.fPrime,
      CubeMove.uPrime,
      CubeMove.lPrime,
      CubeMove.uPrime,
      CubeMove.l,
      CubeMove.u,
    ]);
  }

  CubeState _getYellowFaceTargetState() {
    final state = _getWhiteOnBottomState();
    // Yellow face is already set in _getWhiteOnBottomState.
    // Scramble PLL to show it's not fully solved.
    _swapEdges(
        state, CubeFace.u, 7, CubeFace.f, 1, CubeFace.u, 1, CubeFace.b, 1);
    _swapCorners(state, CubeFace.u, 8, CubeFace.f, 2, CubeFace.r, 0, CubeFace.u,
        0, CubeFace.b, 2, CubeFace.l, 0);
    return state;
  }

  CubeState _getSuneDemoState() {
    // Sune: R U R' U R U2 R'
    // This state should have exactly 1 corner oriented correctly in front-left.
    final state = _getWhiteOnBottomState().applyMoves([
      CubeMove.r,
      CubeMove.u2,
      CubeMove.rPrime,
      CubeMove.uPrime,
      CubeMove.r,
      CubeMove.uPrime,
      CubeMove.rPrime
    ]);
    return state;
  }

  CubeState _getSolvedTargetState() {
    return _getWhiteOnBottomState();
  }

  CubeState _getCornerPermutationDemoState() {
    // Setup for Headlights algorithm: R' F R' B2 R F' R' B2 R2
    // Apply inverse to solved cube: R2 B2 R F R' B2 R F' R
    return _getWhiteOnBottomState().applyMoves([
      CubeMove.r2,
      CubeMove.b2,
      CubeMove.r,
      CubeMove.f,
      CubeMove.rPrime,
      CubeMove.b2,
      CubeMove.r,
      CubeMove.fPrime,
      CubeMove.r,
    ]);
  }

  CubeState _getEdgeCycleDemoState() {
    // Setup for Clockwise Cycle: R2 U R U R' U' R' U' R' U R'
    // Apply Counter-Clockwise Cycle: R U' R U R U R U' R' U' R2
    return _getWhiteOnBottomState().applyMoves([
      CubeMove.r,
      CubeMove.uPrime,
      CubeMove.r,
      CubeMove.u,
      CubeMove.r,
      CubeMove.u,
      CubeMove.r,
      CubeMove.uPrime,
      CubeMove.rPrime,
      CubeMove.uPrime,
      CubeMove.r2,
    ]);
  }

  CubeState _getCrossDemoStateBottom() {
    // 1. Scramble but keep a valid cube
    var state = CubeState.solved().applyMoves(CubeState.generateScramble(20));

    // 2. Fix centers for consistency
    state.u[4] = CubeColor.white;
    state.d[4] = CubeColor.yellow;
    state.f[4] = CubeColor.green;
    state.b[4] = CubeColor.blue;
    state.r[4] = CubeColor.red;
    state.l[4] = CubeColor.orange;

    // 3. Move 3 cross edges to their correct solved positions (U1, U3, U5)
    for (var piece in [
      [CubeColor.white, CubeColor.blue, CubeFace.u, 1, CubeFace.b, 1],
      [CubeColor.white, CubeColor.orange, CubeFace.u, 3, CubeFace.l, 1],
      [CubeColor.white, CubeColor.red, CubeFace.u, 5, CubeFace.r, 1],
    ]) {
      final loc =
          _findEdge(state, piece[0] as CubeColor, piece[1] as CubeColor);
      if (loc != null) {
        _swapEdges(
            state,
            loc[0] as CubeFace,
            loc[1] as int,
            loc[2] as CubeFace,
            loc[3] as int,
            piece[2] as CubeFace,
            piece[3] as int,
            piece[4] as CubeFace,
            piece[5] as int);
      }
    }

    // 4. Move the Green-White edge piece to Right face (R7) / Bottom (D5)
    // We want White on BOTTOM (D5) and Green on SIDE (R7).
    final loc = _findEdge(state, CubeColor.white, CubeColor.green);
    if (loc != null) {
      _swapEdges(state, loc[0] as CubeFace, loc[1] as int, loc[2] as CubeFace,
          loc[3] as int, CubeFace.r, 7, CubeFace.d, 5);
      // Force orientation: Green on Side, White on Bottom
      state.r[7] = CubeColor.green;
      state.d[5] = CubeColor.white;
    }

    return state;
  }

  CubeState _getCrossDemoStateSide() {
    // 1. Scramble but keep a valid cube
    var state = CubeState.solved().applyMoves(CubeState.generateScramble(20));

    // 2. Fix centers for consistency
    state.u[4] = CubeColor.white;
    state.d[4] = CubeColor.yellow;
    state.f[4] = CubeColor.green;
    state.b[4] = CubeColor.blue;
    state.r[4] = CubeColor.red;
    state.l[4] = CubeColor.orange;

    // 3. Move 3 cross edges to their correct solved positions
    for (var piece in [
      [CubeColor.white, CubeColor.blue, CubeFace.u, 1, CubeFace.b, 1],
      [CubeColor.white, CubeColor.orange, CubeFace.u, 3, CubeFace.l, 1],
      [CubeColor.white, CubeColor.red, CubeFace.u, 5, CubeFace.r, 1],
    ]) {
      final loc =
          _findEdge(state, piece[0] as CubeColor, piece[1] as CubeColor);
      if (loc != null) {
        _swapEdges(
            state,
            loc[0] as CubeFace,
            loc[1] as int,
            loc[2] as CubeFace,
            loc[3] as int,
            piece[2] as CubeFace,
            piece[3] as int,
            piece[4] as CubeFace,
            piece[5] as int);
      }
    }

    // 4. Move the Green-White edge piece specifically to Back-Down (B7, D7)
    // We want White on Side (B7) and Green on Bottom (D7).
    final loc = _findEdge(state, CubeColor.white, CubeColor.green);
    if (loc != null) {
      _swapEdges(state, loc[0] as CubeFace, loc[1] as int, loc[2] as CubeFace,
          loc[3] as int, CubeFace.b, 7, CubeFace.d, 7);
      // Force orientation: White on Side (B7), Green on Bottom (D7)
      state.b[7] = CubeColor.white;
      state.d[7] = CubeColor.green;
    }

    return state;
  }

  // Helper to swap two edges
  void _swapEdges(
      CubeState state,
      CubeFace face1A,
      int index1A,
      CubeFace face1B,
      int index1B,
      CubeFace face2A,
      int index2A,
      CubeFace face2B,
      int index2B) {
    var tempA = state.getFace(face1A)[index1A];
    var tempB = state.getFace(face1B)[index1B];

    state.getFace(face1A)[index1A] = state.getFace(face2A)[index2A];
    state.getFace(face1B)[index1B] = state.getFace(face2B)[index2B];

    state.getFace(face2A)[index2A] = tempA;
    state.getFace(face2B)[index2B] = tempB;
  }

  // Find a specific edge in the current state and return its location
  // Returns [FaceA, IndexA, FaceB, IndexB] where FaceA gives ColorA
  List<dynamic>? _findEdge(
      CubeState state, CubeColor colorA, CubeColor colorB) {
    final edges = [
      [CubeFace.u, 7, CubeFace.f, 1],
      [CubeFace.u, 1, CubeFace.b, 1],
      [CubeFace.u, 5, CubeFace.r, 1],
      [CubeFace.u, 3, CubeFace.l, 1],
      [CubeFace.d, 1, CubeFace.f, 7],
      [CubeFace.d, 7, CubeFace.b, 7],
      [CubeFace.d, 5, CubeFace.r, 7],
      [CubeFace.d, 3, CubeFace.l, 7],
      [CubeFace.f, 5, CubeFace.r, 3],
      [CubeFace.f, 3, CubeFace.l, 5],
      [CubeFace.b, 5, CubeFace.l, 3],
      [CubeFace.b, 3, CubeFace.r, 5],
    ];

    for (var edge in edges) {
      if (state.getFace(edge[0] as CubeFace)[edge[1] as int] == colorA &&
          state.getFace(edge[2] as CubeFace)[edge[3] as int] == colorB) {
        return edge;
      }
      if (state.getFace(edge[2] as CubeFace)[edge[3] as int] == colorA &&
          state.getFace(edge[0] as CubeFace)[edge[1] as int] == colorB) {
        return [edge[2], edge[3], edge[0], edge[1]];
      }
    }
    return null;
  }

  void _swapCorners(
      CubeState state,
      CubeFace f1A,
      int i1A,
      CubeFace f1B,
      int i1B,
      CubeFace f1C,
      int i1C,
      CubeFace f2A,
      int i2A,
      CubeFace f2B,
      int i2B,
      CubeFace f2C,
      int i2C) {
    var tA = state.getFace(f1A)[i1A];
    var tB = state.getFace(f1B)[i1B];
    var tC = state.getFace(f1C)[i1C];

    state.getFace(f1A)[i1A] = state.getFace(f2A)[i2A];
    state.getFace(f1B)[i1B] = state.getFace(f2B)[i2B];
    state.getFace(f1C)[i1C] = state.getFace(f2C)[i2C];

    state.getFace(f2A)[i2A] = tA;
    state.getFace(f2B)[i2B] = tB;
    state.getFace(f2C)[i2C] = tC;
  }
}

class _TutorialTab extends StatelessWidget {
  final int step;
  final String label;

  const _TutorialTab({required this.step, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Step $step',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
            Text(label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
