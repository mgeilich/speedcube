import 'package:flutter/material.dart';
import 'cube_renderer.dart';
import '../models/cube_state.dart';
import '../models/cube_move.dart';
import '../models/alg_library.dart';

class DemoOption {
  final String label;
  final VoidCallback onTap;

  const DemoOption({required this.label, required this.onTap});
}

/// Interactive guide for the CFOP (Advanced) method.
class CfopGuideScreen extends StatefulWidget {
  final int initialExpandedStepIndex;
  final double initialScrollOffset;
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
    double? scrollOffset,
  })? onDemoRequested;

  const CfopGuideScreen({
    super.key,
    this.initialExpandedStepIndex = -1,
    this.initialScrollOffset = 0.0,
    this.onDemoRequested,
  });

  @override
  State<CfopGuideScreen> createState() => _CfopGuideScreenState();
}

class _CfopGuideScreenState extends State<CfopGuideScreen> {
  late int _expandedStepIndex = widget.initialExpandedStepIndex;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: widget.initialScrollOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'CFOP Tutorial',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt, color: Color(0xFF6366F1), size: 16),
                SizedBox(width: 4),
                Text(
                  'PRO',
                  style: TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CFOP (Cross, F2L, OLL, PLL) is the standard method for speedcubing. It allows for incredibly fast solves by merging steps and using advanced pattern recognition.',
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            Theme(
              data: Theme.of(context).copyWith(
                cardColor: Colors.transparent,
                dividerColor: Colors.white10,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: ExpansionPanelList(
                elevation: 0,
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    _expandedStepIndex = isExpanded ? index : -1;
                  });
                },
                children: [
                  _buildExpansionPanel(
                    index: 0,
                    title: '1. White Cross',
                    icon: Icons.add_circle_outline,
                    body: _buildCrossBody(),
                  ),
                  _buildExpansionPanel(
                    index: 1,
                    title: '2. Intuitive F2L',
                    icon: Icons.layers,
                    body: _buildF2LBody(),
                  ),
                  _buildExpansionPanel(
                    index: 2,
                    title: '3. OLL (Orient Last Layer)',
                    icon: Icons.wb_sunny_outlined,
                    body: _buildOLLBody(),
                  ),
                  _buildExpansionPanel(
                    index: 3,
                    title: '4. PLL (Permute Last Layer)',
                    icon: Icons.check_circle_outline,
                    body: _buildPLLBody(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ExpansionPanel _buildExpansionPanel({
    required int index,
    required String title,
    required IconData icon,
    required Widget body,
  }) {
    final isExpanded = _expandedStepIndex == index;
    return ExpansionPanel(
      backgroundColor: isExpanded
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.transparent,
      headerBuilder: (BuildContext context, bool _) {
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isExpanded
                  ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isExpanded ? const Color(0xFF6366F1) : Colors.white54,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isExpanded ? Colors.white : Colors.white70,
              fontSize: 18,
              fontWeight: isExpanded ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        );
      },
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        child: body,
      ),
      isExpanded: isExpanded,
      canTapOnHeader: true,
    );
  }

  Widget _buildCrossBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text(
                'Create a white cross on the BOTTOM face. Speedcubers solve on the bottom to look ahead to the next step immediately.',
                style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
              ),
            ),
            const SizedBox(width: 16),
            _buildCubePreview(_getScrambledBaseState(), rotationX: -0.6),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Daisy Method',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'The Daisy Method positions one white edge at a time without disrupting other white edges that are already in position. For a detailed, step-by-step tutorial, please refer to the Layer-by-Layer learning guide from the main menu.',
          style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        const Text(
          'Advanced Cross',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Mathematical analysis proves that ANY cross can be solved in 8 moves or fewer. Instead of solving one edge piece at a time, advanced solvers determine the optimal sequence of moves to place all four edges relative to each other.\n\nOnce the edges are correctly placed relative to each other, a single bottom-layer turn (D, D\', or D2) will align the entire cross with the side centers.',
          style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
        ),
        _buildDemoButtons([
          DemoOption(
            label: 'Show Advanced Cross Demo',
            onTap: () {
              widget.onDemoRequested?.call(
                0, 
                _getAdvancedCrossDemoState(), 
                moves: [
                  CubeMove.fPrime, 
                  CubeMove.lPrime, 
                  CubeMove.bPrime, 
                  CubeMove.rPrime, 
                  CubeMove.d
                ], 
                initialRotationX: -0.6,
                targetRotationX: -0.6,
                initialRotationY: 0.6,
                targetRotationY: 0.6,
              );
            },
          ),
        ]),
      ],
    );
  }

  Widget _buildF2LBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text(
                'F2L (First Two Layers) involves pairing each corner with its corresponding edge in the top layer and inserting them into their final position simultaneously. When all four corner/edge pairs have been positioned, the first two layers of the cube are complete.',
                style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
              ),
            ),
            const SizedBox(width: 16),
            _buildCubePreview(_getF2LCompleteState(), rotationX: 0.4),
          ],
        ),
        const SizedBox(height: 32),

        // --- Step 2a: Extraction ---
        const Text('Step 2a: Piece Extraction', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'If a corner with a white sticker is in the wrong position on the bottom layer, or a matching edge is in the middle layer, you must extract them to the top layer first while preserving the white cross on the bottom face.',
          style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 16),
        _buildIllustration(
          '1. Corner Extraction',
          'If a corner is in the wrong position on the bottom layer, use R U R\' to bring it to the top.',
          _getF2LCornerExtractionState(),
          rotationX: 0.4,
          rotationY: 0.75,
          highlightedStickers: [
            MapEntry(CubeFace.f, 8),
            MapEntry(CubeFace.r, 6),
            MapEntry(CubeFace.d, 2),
          ],
        ),
        _buildDemoButtons([
          DemoOption(
            label: 'Show Corner Extraction',
            onTap: () {
              _requestDemo(1, _getF2LCornerExtractionState(), 
                moves: [CubeMove.r, CubeMove.u, CubeMove.rPrime], 
                initialRotationX: 0.4,
                initialRotationY: 0.75,
              );
            },
          ),
        ]),

        const SizedBox(height: 24),

        _buildIllustration(
          '2. Edge Extraction',
          'If an edge is stuck in the middle, use R U R\' U\' to extract it.',
          _getF2LEdgeExtractionState(),
          rotationX: 0.4,
          rotationY: 0.75,
          highlightedStickers: [
            MapEntry(CubeFace.f, 5),
            MapEntry(CubeFace.r, 3),
          ],
        ),
        _buildDemoButtons([
          DemoOption(
            label: 'Show Edge Extraction',
            onTap: () {
              _requestDemo(1, _getF2LEdgeExtractionState(),
                moves: [CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime],
                initialRotationX: 0.4,
                initialRotationY: 0.75,
              );
            },
          ),
        ]),

        const SizedBox(height: 24),

        _buildIllustration(
          '3. Separating Adjacent Pieces',
          'If a corner and edge are next to each other in the top layer but not correctly oriented or matched, use R U2 R\' to separate them.',
          _getF2LSeparationState(),
          rotationX: 0.4,
          rotationY: 0.75,
          highlightedStickers: [
            MapEntry(CubeFace.u, 8),
            MapEntry(CubeFace.f, 2),
            MapEntry(CubeFace.r, 0),
            MapEntry(CubeFace.u, 5),
            MapEntry(CubeFace.r, 1),
          ],
        ),
        _buildDemoButtons([
          DemoOption(
            label: 'Show Separation Demo',
            onTap: () {
              _requestDemo(1, _getF2LSeparationState(),
                moves: [CubeMove.r, CubeMove.u2, CubeMove.rPrime],
                initialRotationX: 0.4,
                initialRotationY: 0.75,
              );
            },
          ),
        ]),

        const Divider(height: 48, color: Colors.white10),

        // --- Step 2b: Core Case - White on Side ---
        const Text('Step 2b: Pairing & Insertion', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'Once you have a corner with a white sticker and matching edge in the top layer, rotate the top layer (U) until the corner with the white sticker is directly above its final position and rotate the cube to put it into the top front right position. The white sticker will either be facing Right, Forward, or Up.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 8),
        const Text(
          'Next, look at the top sticker on the matching edge. It will either be the same color as the top sticker on the corner or not. We handle each of these cases differently.',
          style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),

        // Case 1: White on Side (Right)
        _buildIllustration(
          'Case 1: White Facing Right',
          'The white sticker faces the Right side. Check if the top sticker of the edge matches the corner top color.',
          _getF2LMatchingSideState(),
          rotationX: 0.4,
          rotationY: 0.75,
        ),
        const SizedBox(height: 12),
        _buildDemoButtons([
          DemoOption(
            label: 'Matching Edge',
            onTap: () {
              _requestDemo(1, _getF2LMatchingSideState(),
                moves: [CubeMove.u, CubeMove.fPrime, CubeMove.u2, CubeMove.f, CubeMove.u2, CubeMove.fPrime, CubeMove.u, CubeMove.f],
                initialRotationX: 0.4,
                initialRotationY: 0.75,
              );
            },
          ),
          DemoOption(
            label: 'Non-Matching Edge',
            onTap: () {
              _requestDemo(1, _getF2LNonMatchingSideState(),
                moves: [CubeMove.r, CubeMove.u, CubeMove.rPrime],
                initialRotationX: 0.4,
                initialRotationY: 0.75,
              );
            },
          ),
        ]),

        const SizedBox(height: 32),

        // Case 2: White Facing Forward
        _buildIllustration(
          'Case 2: White Facing Forward',
          'The white sticker faces you (Forward). This is the mirror of Case 1.',
          _getF2LMatchingFrontState(),
          rotationX: 0.4,
          rotationY: 0.75,
        ),
        const SizedBox(height: 12),
        _buildDemoButtons([
          DemoOption(
            label: 'Matching Edge',
            onTap: () {
              _requestDemo(1, _getF2LMatchingFrontState(),
                moves: [CubeMove.uPrime, CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.u2, CubeMove.r, CubeMove.uPrime, CubeMove.rPrime],
                initialRotationX: 0.4,
                initialRotationY: 0.75,
              );
            },
          ),
          DemoOption(
            label: 'Non-Matching Edge',
            onTap: () {
              _requestDemo(1, _getF2LNonMatchingFrontState(),
                moves: [CubeMove.uPrime, CubeMove.r, CubeMove.uPrime, CubeMove.r2, CubeMove.u, CubeMove.r, CubeMove.u2, CubeMove.fPrime, CubeMove.u, CubeMove.f],
                initialRotationX: 0.4,
                initialRotationY: 0.75,
              );
            },
          ),
        ]),

        const SizedBox(height: 32),

        // Case 3: White Facing Up
        _buildIllustration(
          'Case 3: White Facing Up',
          'The white sticker faces Up. This requires a setup move to rotate the corner so white faces the side.',
          _getF2LTopState(),
          rotationX: 0.4,
          rotationY: 0.75,
        ),
        const SizedBox(height: 12),
        _buildDemoButtons([
          DemoOption(
            label: 'Show Case 3 Demo',
            onTap: () {
              _requestDemo(1, _getF2LTopState(),
                moves: [CubeMove.uPrime, CubeMove.fPrime, CubeMove.u2, CubeMove.f, CubeMove.uPrime, CubeMove.fPrime, CubeMove.u, CubeMove.f],
                initialRotationX: 0.4,
                initialRotationY: 0.75,
              );
            },
          ),
        ]),
      ],
    );
  }

  Widget _buildOLLBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OLL orients the yellow face. Using "2-Look OLL," you solve the cross first, then orient the corners. This requires about 10 algorithms instead of 57.',
          style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
        ),
        const SizedBox(height: 32),
        
        // --- Step 3a: The Cross ---
        const Text('Step 3a: Orient Edges (The Cross)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'First, orient the yellow edges to form a cross. Depending on your starting pattern, use one of these sequences:',
          style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 16),
        
        _buildOLLCaseRow('1. The Dot', "(F R U R' U' F') U2 (F U R U' R' F')", _getOLLCrossDotState()),
        const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 24),
          child: Text(
            'Tip: "The Dot" is just the Bar algorithm followed by the Angle algorithm with U2 in between.',
            style: TextStyle(color: Colors.white38, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ),
        _buildOLLCaseRow('2. The Angle (L)', "F U R U' R' F'", _getOLLCrossAngleState()),
        _buildOLLCaseRow('3. The Bar', "F R U R' U' F'", _getOLLCrossBarState()),
        
        const Divider(height: 48, color: Colors.white10),

        // --- Step 3b: Corner Orientation ---
        const Text('Step 3b: Orient Corners', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'Once the cross is solved, there are exactly 7 patterns for the remaining corners. Match your pattern and execute the corresponding algorithm.',
          style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),

        _buildPatternRecognitionGuide(),

        const SizedBox(height: 24),
        
        _buildOCLLGrid(),
      ],
    );
  }

  Widget _buildPatternRecognitionGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.search_rounded, color: Color(0xFF6366F1), size: 20),
              SizedBox(width: 8),
              Text(
                'Pattern Recognition Guide',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecognitionStep(
            '1. Count yellow corners ON TOP',
            'How many yellow corners are already solved (yellow stickers facing Up)?',
          ),
          const SizedBox(height: 12),
          _buildRecognitionStep(
            '2. Find your group',
            '• 0 Corners on top: Headlights (H) or Pi\n• 1 Corner on top: Sune or Anti-Sune (The "Fish")\n• 2 Corners on top: U, T, or L (Bowtie)',
          ),
          const Divider(height: 24, color: Colors.white10),
          const Text(
            'Q: What if I have MORE yellow stickers on top than the demo?',
            style: TextStyle(color: Color(0xFF6366F1), fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Extra yellow stickers on top are great! It just means you are already in a 1-corner or 2-corner case. If 4 are on top, you are finished with OLL!',
            style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildRecognitionStep(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.4)),
      ],
    );
  }

  Widget _buildOLLCaseRow(String title, String alg, CubeState state) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCubePreview(state, rotationX: 0.5),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAlgorithmText(alg),
                    const SizedBox(height: 8),
                    _buildShowMeButton(
                      label: 'Show Me',
                      color: const Color(0xFF6366F1),
                      onPressed: () => _requestDemo(2, state, moves: _parseAlg(alg), initialRotationX: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOCLLGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOCLLGroup('0 Corners on Top', [
          MapEntry('H (Double Sune)', 'oll21'),
          MapEntry('Pi', 'oll22'),
        ]),
        const SizedBox(height: 32),
        _buildOCLLGroup('1 Corner on Top (The Fish)', [
          MapEntry('Sune', 'oll27'),
          MapEntry('Anti-Sune', 'oll26'),
        ]),
        const SizedBox(height: 32),
        _buildOCLLGroup('2 Corners on Top', [
          MapEntry('U (Headlights)', 'oll23'),
          MapEntry('T (Chamfer)', 'oll24'),
          MapEntry('L (Bowtie)', 'oll25'),
        ]),
      ],
    );
  }

  Widget _buildOCLLGroup(String title, List<MapEntry<String, String>> cases) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF6366F1),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 24,
          children: cases.map((e) {
            final algCase = AlgLibrary.ollCases.firstWhere((a) => a.id == e.value);
            final state = _getOCLLState(e.value);
            return SizedBox(
              width: 160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _buildCubePreview(state, rotationX: 0.5),
                  const SizedBox(height: 8),
                  Text(algCase.algorithm, style: const TextStyle(color: Colors.white38, fontFamily: 'monospace', fontSize: 10)),
                  const SizedBox(height: 8),
                  _buildShowMeButton(
                    label: 'Demo',
                    color: const Color(0xFF6366F1),
                    onPressed: () => _requestDemo(2, state, moves: algCase.algorithmMoves, initialRotationX: 0.5),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPLLBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLL (Permute Last Layer) moves the top pieces into their final positions while keeping them oriented correctly.',
          style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
        ),
        const SizedBox(height: 24),
        
        const Text('Step 4a: Permute Corners', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        const Text(
          'Look for "Headlights" (two corners of the same color on one side).',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 16),
        
        _buildPLLCornerStep('1. Headlights Found', 
          'Put headlights in the back and do Aa-Perm.', 
          'pll_aa', 
          "R' F R' B2 R F' R' B2 R2"
        ),
        
        const SizedBox(height: 16),
        
        _buildPLLCornerStep('2. No Headlights', 
          'Do Y-Perm from any angle, then you will have headlights.', 
          'pll_y', 
          "F R U' R' U' R U R' F' R U R' U' R' F R F'"
        ),

        const SizedBox(height: 32),
        const Divider(color: Colors.white10),
        const SizedBox(height: 24),
        
        const Text('Step 4b: Permute Edges', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        const Text(
          'Now that corners are solved, use one of these 4 algorithms to finish the cube.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 24),
        
        _buildPLLEdgeGrid(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPLLCornerStep(String title, String desc, String algId, String notation) {
    final state = _getPLLState(algId);
    final algCase = AlgLibrary.pllCases.firstWhere((a) => a.id == algId);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCubePreview(state, rotationX: 0.4),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notation, style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12)),
                  const SizedBox(height: 12),
                  _buildShowMeButton(
                    label: 'Show Me',
                    color: const Color(0xFF6366F1),
                    onPressed: () => _requestDemo(3, state, moves: algCase.algorithmMoves, initialRotationX: 0.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPLLEdgeGrid() {
    final cases = [
      MapEntry('Ua-Perm', 'pll_ua'),
      MapEntry('Ub-Perm', 'pll_ub'),
      MapEntry('H-Perm', 'pll_h'),
      MapEntry('Z-Perm', 'pll_z'),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 24,
      children: cases.map((e) {
        final algCase = AlgLibrary.pllCases.firstWhere((a) => a.id == e.value);
        final state = _getPLLState(e.value);
        return SizedBox(
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildCubePreview(state, rotationX: 0.4),
              const SizedBox(height: 8),
              Text(algCase.algorithm, style: const TextStyle(color: Colors.white38, fontFamily: 'monospace', fontSize: 10)),
              const SizedBox(height: 8),
              _buildShowMeButton(
                label: 'Demo',
                color: const Color(0xFF6366F1),
                onPressed: () => _requestDemo(3, state, moves: algCase.algorithmMoves, initialRotationX: 0.4),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCubePreview(CubeState state, {double rotationX = -0.6}) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: CustomPaint(
        painter: CubeRenderer(
          cubeState: state,
          rotationX: rotationX,
          rotationY: 0.6,
        ),
        size: const Size(100, 100),
      ),
    );
  }

  void _requestDemo(
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
  }) {
    widget.onDemoRequested?.call(
      stepIndex,
      initialState,
      moves: moves,
      initialRotationX: initialRotationX,
      targetRotationX: targetRotationX,
      initialRotationY: initialRotationY,
      targetRotationY: targetRotationY,
      demoType: demoType,
      stickerLabels: stickerLabels,
      targetPieces: targetPieces,
      scrollOffset: _scrollController.offset,
    );
  }

  Widget _buildIllustration(
    String title,
    String description,
    CubeState cubeState, {
    List<MapEntry<CubeFace, int>>? highlightedStickers,
    double rotationX = -0.4,
    double rotationY = 0.6,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(description, style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.5)),
            ),
            const SizedBox(width: 16),
            Container(
              width: 100,
              height: 100,
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
                ),
                size: const Size(100, 100),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDemoButtons(List<DemoOption> demoOptions) {
    return Column(
      children: [
        const SizedBox(height: 24),
        ...demoOptions.map((option) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildShowMeButton(label: option.label, color: const Color(0xFF6366F1), onPressed: option.onTap),
        )),
      ],
    );
  }

  Widget _buildShowMeButton({required String label, required Color color, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
              Text(label.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
        ),
      ),
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
          Text(text, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }


  // ── State Generators ──────────────────────────────────────────────────────



  CubeState _getWhiteOnBottomState() {
    final state = CubeState.solved();
    for (int i = 0; i < 9; i++) {
      state.u[i] = CubeColor.yellow;
    }
    for (int i = 0; i < 9; i++) {
      state.d[i] = CubeColor.white;
    }
    return state;
  }

  /// Returns a state where the bottom two layers (F2L) are solved.
  CubeState _getF2LCompleteState() {
    // Start with white on bottom (Yellow on top)
    final state = CubeState.yellowTopSolved();
    // Apply a T-Perm to scramble the top layer while preserving the bottom two layers
    return state.applyMoves([
      CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime,
      CubeMove.rPrime, CubeMove.f, CubeMove.r2, CubeMove.uPrime,
      CubeMove.rPrime, CubeMove.uPrime, CubeMove.r, CubeMove.u,
      CubeMove.rPrime, CubeMove.fPrime
    ]);
  }

  /// Returns a state where the White Cross is solved, but the rest is scrambled.
  CubeState _getScrambledBaseState() {
    // Start with solved cross on bottom
    final state = _getWhiteOnBottomState();
    
    // Apply several noise moves that preserve the cross
    // Using U/U'/U2 and specific combinations
    final noise = [
      CubeMove.u, CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime,
      CubeMove.lPrime, CubeMove.uPrime, CubeMove.l, CubeMove.u,
      CubeMove.f, CubeMove.u, CubeMove.fPrime, CubeMove.uPrime,
      CubeMove.bPrime, CubeMove.uPrime, CubeMove.b, CubeMove.u,
    ];
    return state.applyMoves(noise);
  }

  CubeState _getAdvancedCrossDemoState() {
    final state = _getScrambledBaseState();
    return state.applyMoves([
      CubeMove.dPrime, 
      CubeMove.r, 
      CubeMove.b, 
      CubeMove.l, 
      CubeMove.f
    ]);
  }



  CubeState _getOLLCrossDotState() {
    // Dot = Bar + U2 + Angle. Since it's its own inverse for orientation, we apply it to a solved cross.
    final state = CubeState.yellowTopSolved().applyMoves(_parseAlg("F R U R' U' F' U2 F U R U' R' F'"));
    return _forceF2LSolved(_clearTopCorners(state));
  }

  CubeState _getOLLCrossAngleState() {
    // Setup for Angle: apply inverse of Angle algorithm (F U R U' R' F') which is (F R U R' U' F')
    final state = CubeState.yellowTopSolved().applyMoves(_parseAlg("F R U R' U' F'"));
    return _forceF2LSolved(_clearTopCorners(state));
  }

  CubeState _getOLLCrossBarState() {
    // Setup for Bar: apply inverse of Bar algorithm (F R U R' U' F') which is (F U R U' R' F')
    final state = CubeState.yellowTopSolved().applyMoves(_parseAlg("F U R U' R' F'"));
    return _forceF2LSolved(_clearTopCorners(state));
  }

  CubeState _getOCLLState(String algId) {
    final state = CubeState.yellowTopSolved();
    final setupState = state.applyMoves(AlgLibrary.ollCases.firstWhere((a) => a.id == algId).setupMoveList);
    return _forceF2LSolved(setupState);
  }

  CubeState _getPLLState(String algId) {
    final state = CubeState.yellowTopSolved();
    final setupState = state.applyMoves(AlgLibrary.pllCases.firstWhere((a) => a.id == algId).setupMoveList);
    return _forceF2LSolved(setupState);
  }

  CubeState _clearTopCorners(CubeState state) {
    state.u[0] = CubeColor.blue;
    state.u[2] = CubeColor.orange;
    state.u[6] = CubeColor.green;
    state.u[8] = CubeColor.red;
    return state;
  }

  CubeState _forceF2LSolved(CubeState state) {
    // Set bottom face to White
    for (int i = 0; i < 9; i++) {
      state.d[i] = CubeColor.white;
    }
    // Set side colors for middle and bottom layers (indices 3-8)
    for (int i = 3; i < 9; i++) {
      state.f[i] = CubeColor.green;
      state.b[i] = CubeColor.blue;
      state.l[i] = CubeColor.red;
      state.r[i] = CubeColor.orange;
    }
    return state;
  }

  // --- NEW F2L Case Generators ---

  CubeState _getF2LCornerExtractionState() {
    // Only corner trapped in bottom slot
    final state = _getScrambledBaseState();
    // Target corner: White, Orange, Green (trapped in FRB slot)
    state.f[8] = CubeColor.white;
    state.r[6] = CubeColor.orange;
    state.d[2] = CubeColor.green;
    state.applyMoves([CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime]);
    return state;
  }

  CubeState _getF2LEdgeExtractionState() {
    // Only edge trapped in middle slot
    final state = _getScrambledBaseState();
    // Target edge: Orange, Green (trapped in FR middle slot)
    state.f[5] = CubeColor.orange;
    state.r[3] = CubeColor.green;
    // User requested the corresponding corner (White/Orange/Green) be on top too
    // Position it at UFR (Back-Right-Top)
    state.u[8] = CubeColor.white;
    state.r[0] = CubeColor.orange;
    state.b[2] = CubeColor.green;
    
    state.applyMoves([CubeMove.lPrime, CubeMove.uPrime, CubeMove.l, CubeMove.u]);
    return state;
  }

  CubeState _getF2LMatchingSideState() {
    final state = CubeState.yellowTopSolved();
    // Clear FR slot (Orange/Green)
    state.f[5] = CubeColor.red; state.r[3] = CubeColor.red;
    state.f[8] = CubeColor.red; state.r[6] = CubeColor.red; state.d[2] = CubeColor.white;

    // Corner at UFR: White on R, Orange on U, Green on F
    state.u[8] = CubeColor.orange;
    state.f[2] = CubeColor.green;
    state.r[0] = CubeColor.white;
    // Edge at UB: Orange on U, Green on B (Matching top color: Orange)
    state.u[1] = CubeColor.orange;
    state.b[1] = CubeColor.green; 
    return state;
  }

  CubeState _getF2LNonMatchingSideState() {
    // Start with a state where the target pieces are NOT in their slots
    final state = CubeState.yellowTopSolved();
    // Clear the original Orange/Green pieces in the FR slot to avoid duplicates
    state.f[5] = CubeColor.red; // Edge side
    state.r[3] = CubeColor.red; // Edge side
    state.f[8] = CubeColor.red; // Corner side
    state.r[6] = CubeColor.red; // Corner side
    state.d[2] = CubeColor.white;  // Corner bottom (keep it white or something neutral)

    // Corner at UFR: White on R, Green on F, Orange on U
    state.u[8] = CubeColor.orange;
    state.f[2] = CubeColor.green;
    state.r[0] = CubeColor.white;
    // Edge at UB: Green on U, Orange on B (Non-matching top colors)
    state.u[1] = CubeColor.green;
    state.b[1] = CubeColor.orange;
    return state;
  }

  CubeState _getF2LTopState() {
    final state = CubeState.yellowTopSolved();
    // Clear FR slot (Orange/Green)
    state.f[5] = CubeColor.red; state.r[3] = CubeColor.red;
    state.f[8] = CubeColor.red; state.r[6] = CubeColor.red; state.d[2] = CubeColor.white;

    // Corner at UFR: White on Top, Orange on Front, Green on Right (Reversed)
    state.u[8] = CubeColor.white;
    state.f[2] = CubeColor.orange;
    state.r[0] = CubeColor.green;
    // Edge at UL: Orange on Top, Green on Left (Reversed Orange/Green)
    state.u[3] = CubeColor.orange;
    state.l[1] = CubeColor.green;
    return state;
  }

  CubeState _getF2LMatchingFrontState() {
    final state = CubeState.yellowTopSolved();
    // Clear FR slot (Orange/Green)
    state.f[5] = CubeColor.red; state.r[3] = CubeColor.red;
    state.f[8] = CubeColor.red; state.r[6] = CubeColor.red; state.d[2] = CubeColor.white;

    // Corner at UFR: White on F, Orange on R, Green on U
    state.u[8] = CubeColor.green;
    state.f[2] = CubeColor.white;
    state.r[0] = CubeColor.orange;
    // Edge at UB: Green on U, Orange on B (Matching top color: Green)
    state.u[1] = CubeColor.green;
    state.b[1] = CubeColor.orange;
    return state;
  }

  CubeState _getF2LNonMatchingFrontState() {
    final state = CubeState.yellowTopSolved();
    // Clear FR slot
    state.f[5] = CubeColor.red; state.r[3] = CubeColor.red;
    state.f[8] = CubeColor.red; state.r[6] = CubeColor.red; state.d[2] = CubeColor.white;

    // Corner at UFR: White on F, Green on R, Orange on U
    state.u[8] = CubeColor.orange;
    state.f[2] = CubeColor.white;
    state.r[0] = CubeColor.green;
    // Edge at UB: Green on U, Orange on B (Non-matching top colors)
    state.u[1] = CubeColor.green;
    state.b[1] = CubeColor.orange;
    return state;
  }

  CubeState _getF2LSeparationState() {
    final state = CubeState.yellowTopSolved();
    // Clear FR slot
    state.f[5] = CubeColor.red; state.r[3] = CubeColor.red;
    state.f[8] = CubeColor.red; state.r[6] = CubeColor.red; state.d[2] = CubeColor.white;

    // Corner at UFR: White on R, Orange on F, Green on U
    state.u[8] = CubeColor.green;
    state.f[2] = CubeColor.orange;
    state.r[0] = CubeColor.white;
    // Edge at UR: Orange on U, Green on R (Mismatched with corner)
    state.u[5] = CubeColor.orange;
    state.r[1] = CubeColor.green;
    return state;
  }

  List<CubeMove> _parseAlg(String notation) {
    if (notation.trim().isEmpty) return [];
    // Remove parentheses before parsing
    final cleaned = notation.replaceAll('(', '').replaceAll(')', '');
    return cleaned
        .trim()
        .split(RegExp(r'\s+'))
        .map((s) => CubeMove.parse(s))
        .whereType<CubeMove>()
        .toList();
  }
}
