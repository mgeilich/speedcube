import 'package:flutter/material.dart';
import 'cube_renderer.dart';
import '../models/cube_state.dart';
import '../models/cube_move.dart';
import '../solver/petrus_solver.dart';

class DemoOption {
  final String label;
  final VoidCallback onTap;

  const DemoOption({required this.label, required this.onTap});
}

/// Interactive guide for the Petrus method.
class PetrusGuideScreen extends StatefulWidget {
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
  final void Function(int index)? onTabChanged;

  const PetrusGuideScreen({
    super.key,
    this.initialExpandedStepIndex = -1,
    this.initialScrollOffset = 0.0,
    this.onDemoRequested,
    this.onTabChanged,
  });

  @override
  State<PetrusGuideScreen> createState() => _PetrusGuideScreenState();
}

class _PetrusGuideScreenState extends State<PetrusGuideScreen>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final TabController _tabController;
  bool _isGeneratingDemo = false;

  @override
  void initState() {
    super.initState();
    _scrollController =
        ScrollController(initialScrollOffset: widget.initialScrollOffset);
    _tabController = TabController(
      length: 5,
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startDynamicDemo(int stageIndex) async {
    if (_isGeneratingDemo) return;
    setState(() => _isGeneratingDemo = true);

    try {
      // 1. Generate a random scramble
      final scrambleMoves = CubeState.generateScramble(20);
      final scrambledState = CubeState.solved().applyMoves(scrambleMoves);

      // 2. Solve the cube using Petrus
      final solveResult = await PetrusSolver.solve(scrambledState);
      
      if (solveResult.steps.length <= stageIndex) {
         // Should not happen for a valid scramble
         throw Exception("Failed to generate Petrus solution for this scramble.");
      }

      // 3. Prepare the demo state
      // Initial state for demo is scrambledState + all moves from previous stages applied
      CubeState demoInitialState = scrambledState;
      for (int i = 0; i < stageIndex; i++) {
        demoInitialState = demoInitialState.applyMoves(solveResult.steps[i].moves);
      }

      // 4. Request the demo
      widget.onDemoRequested?.call(
        stageIndex,
        demoInitialState,
        moves: solveResult.steps[stageIndex].moves,
        demoType: 'petrus',
        scrollOffset: _scrollController.offset,
        initialRotationX: _getRotationForStage(stageIndex).dx,
        initialRotationY: _getRotationForStage(stageIndex).dy,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating demo: \$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingDemo = false);
      }
    }
  }

  Offset _getRotationForStage(int stageIndex) {
    switch (stageIndex) {
      case 0: return const Offset(-0.4, 0.75); // 2x2x2 (back-down-left)
      case 1: return const Offset(-0.4, 0.45); // 2x2x3 (front-left view)
      case 2: return const Offset(0.4, 0.75);  // EO (top view)
      case 3: return const Offset(-0.4, -0.75); // F2L (right view)
      case 4: return const Offset(0.5, 0.75);  // LL (top view)
      default: return const Offset(0.4, 0.75);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F25),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Petrus Tutorial',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              tabs: const [
                Tab(text: '2x2x2'),
                Tab(text: '2x2x3'),
                Tab(text: 'EO'),
                Tab(text: 'F2L'),
                Tab(text: 'LL'),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildTabPage(_buildStage1Body()),
              _buildTabPage(_buildStage2Body()),
              _buildTabPage(_buildStage3Body()),
              _buildTabPage(_buildStage4Body()),
              _buildTabPage(_buildStage5Body()),
            ],
          ),
          if (_isGeneratingDemo)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabPage(Widget body) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: body,
    );
  }

  Widget _buildStage1Body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('Stage 1: The 2x2x2 Block'),
        _buildDescription(
          'Instead of a cross, Petrus starts by building a small 2x2x2 block in any corner. Usually, we build it at the Back-Down-Left (dBL) position.',
        ),
        const SizedBox(height: 24),
        _buildIllustration(
          'Target: 2x2x2 Block',
          'Solve the corner piece and its three adjacent edges.',
          _get2x2x2SolvedState(),
          highlightedStickers: _get2x2x2Stickers(),
          dimNonHighlighted: true,
          rotationX: -0.4,
          rotationY: 0.75,
        ),
        const SizedBox(height: 32),
        _buildDemoButtons([
          DemoOption(
            label: 'Start Interactive 2x2x2 Demo',
            onTap: () => _startDynamicDemo(0),
          ),
        ]),
      ],
    );
  }

  Widget _buildStage2Body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('Stage 2: Expand to 2x2x3'),
        _buildDescription(
          'Now, expand your 2x2x2 block into a 2x2x3 block. This is done by adding another 1x2x2 section to one side of the existing block.',
        ),
        const SizedBox(height: 24),
        _buildIllustration(
          'Target: 2x2x3 Block',
          'The left side of the cube is now 2/3 complete.',
          _get2x2x3SolvedState(),
          highlightedStickers: _get2x2x3Stickers(),
          dimNonHighlighted: true,
          rotationX: -0.4,
          rotationY: 0.45,
        ),
        const SizedBox(height: 32),
        _buildDemoButtons([
          DemoOption(
            label: 'Start Interactive 2x2x3 Demo',
            onTap: () => _startDynamicDemo(1),
          ),
        ]),
      ],
    );
  }

  Widget _buildStage3Body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('Stage 3: Edge Orientation (EO)'),
        _buildDescription(
          'This is the heart of the Petrus method. Orient all remaining edges so that they can be solved using only <U, R> moves. This eliminates the need for rotations later!',
        ),
        const SizedBox(height: 24),
        _buildIllustration(
          'Oriented Edges',
          'All top and front edges are now oriented.',
          _get2x2x3SolvedState(),
          highlightedStickers: _getStage3Stickers(),
          dimNonHighlighted: true,
          rotationX: 0.4,
          rotationY: 0.6,
        ),
        const SizedBox(height: 32),
        _buildDemoButtons([
          DemoOption(
            label: 'Start Interactive EO Demo',
            onTap: () => _startDynamicDemo(2),
          ),
        ]),
      ],
    );
  }

  Widget _buildStage4Body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('Stage 4: Finish F2L'),
        _buildDescription(
          'With edges oriented, you can now finish the first two layers (F2L) using only <U, R> moves. This part is extremely fast because you never have to rotate the cube.',
        ),
        const SizedBox(height: 24),
        _buildIllustration(
          'F2L Complete',
          'The entire bottom two layers are solved.',
          _getF2LSolvedState(),
          highlightedStickers: _getF2LStickers(),
          dimNonHighlighted: true,
          rotationX: -0.4,
          rotationY: -0.75,
        ),
        const SizedBox(height: 32),
        _buildDemoButtons([
          DemoOption(
            label: 'Start Interactive F2L Demo',
            onTap: () => _startDynamicDemo(3),
          ),
        ]),
      ],
    );
  }

  Widget _buildStage5Body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('Stage 5: Last Layer'),
        _buildDescription(
          'Finally, solve the top layer. Since all edges were already oriented in Stage 3, you ALWAYS start with a cross on top! This makes the final stage much faster.',
        ),
        const SizedBox(height: 24),
        _buildIllustration(
          'Solved Cube',
          'The final stage is orientation and permutation.',
          CubeState.solved(),
          rotationX: 0.5,
          rotationY: 0.75,
        ),
        const SizedBox(height: 32),
        _buildProTip(),
        const SizedBox(height: 24),
        _buildDemoButtons([
          DemoOption(
            label: 'Start Interactive LL Demo',
            onTap: () => _startDynamicDemo(4),
          ),
        ]),
      ],
    );
  }

  Widget _buildProTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Color(0xFF6366F1), size: 20),
              SizedBox(width: 8),
              Text(
                'HOW TO SOLVE THE LAST LAYER',
                style: TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Because the edges are already oriented, you can use techniques from other methods to finish the cube:',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          _buildTipPoint('CFOP Method', 'Use OLL (Orientation) and PLL (Permutation) for a fast finish.'),
          const SizedBox(height: 8),
          _buildTipPoint('Winter Variation', 'Skip OLL entirely! Since edges are already oriented, you can solve all corners while inserting your last F2L pair.'),
          const SizedBox(height: 8),
          _buildTipPoint('Layer-by-Layer', 'Follow the beginner steps for corner placement and orientation.'),
        ],
      ),
    );
  }

  Widget _buildTipPoint(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '$title: ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                TextSpan(text: desc, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDescription(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
      ),
    );
  }

  Widget _buildIllustration(String title, String subtitle, CubeState state,
      {double rotationX = 0, double rotationY = 0, List<MapEntry<CubeFace, int>>? highlightedStickers, bool dimNonHighlighted = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
            child: CustomPaint(
              painter: CubeRenderer(
                cubeState: state,
                rotationX: rotationX,
                rotationY: rotationY,
                highlightedStickers: highlightedStickers,
                dimNonHighlighted: dimNonHighlighted,
              ),
              size: const Size(140, 140),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDemoButtons(List<DemoOption> options) {
    return Column(
      children: options.map((opt) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
              foregroundColor: const Color(0xFF6366F1),
              side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            onPressed: opt.onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_filled_rounded, size: 20),
                const SizedBox(width: 12),
                Text(opt.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }

  // --- Illustration Helpers ---

  CubeState _get2x2x2SolvedState() {
    return CubeState.solved(); // Highlighted stickers will make it clear
  }

  List<MapEntry<CubeFace, int>> _get2x2x2Stickers() {
    return [
      // Down face (Back-Left quadrant)
      const MapEntry(CubeFace.d, 3), const MapEntry(CubeFace.d, 4),
      const MapEntry(CubeFace.d, 6), const MapEntry(CubeFace.d, 7),
      // Left face (Down-Back quadrant)
      const MapEntry(CubeFace.l, 3), const MapEntry(CubeFace.l, 4),
      const MapEntry(CubeFace.l, 6), const MapEntry(CubeFace.l, 7),
      // Back face (Down-Left quadrant)
      const MapEntry(CubeFace.b, 4), const MapEntry(CubeFace.b, 5),
      const MapEntry(CubeFace.b, 7), const MapEntry(CubeFace.b, 8),
    ];
  }

  CubeState _get2x2x3SolvedState() {
    return CubeState.solved();
  }

  List<MapEntry<CubeFace, int>> _get2x2x3Stickers() {
    return [
      // Left face (Bottom 2/3: Middle and Down rows)
      const MapEntry(CubeFace.l, 3), const MapEntry(CubeFace.l, 4), const MapEntry(CubeFace.l, 5),
      const MapEntry(CubeFace.l, 6), const MapEntry(CubeFace.l, 7), const MapEntry(CubeFace.l, 8),
      // Down face (Left 2/3: Back and Middle columns)
      const MapEntry(CubeFace.d, 0), const MapEntry(CubeFace.d, 1),
      const MapEntry(CubeFace.d, 3), const MapEntry(CubeFace.d, 4),
      const MapEntry(CubeFace.d, 6), const MapEntry(CubeFace.d, 7),
      // Back face (Down-Left quadrant)
      const MapEntry(CubeFace.b, 4), const MapEntry(CubeFace.b, 5),
      const MapEntry(CubeFace.b, 7), const MapEntry(CubeFace.b, 8),
      // Front face (Down-Left quadrant)
      const MapEntry(CubeFace.f, 3), const MapEntry(CubeFace.f, 4),
      const MapEntry(CubeFace.f, 6), const MapEntry(CubeFace.f, 7),
    ];
  }

  CubeState _getF2LSolvedState() {
    return CubeState.solved();
  }

  List<MapEntry<CubeFace, int>> _getF2LStickers() {
    final List<MapEntry<CubeFace, int>> res = [];
    for (final face in [CubeFace.d, CubeFace.f, CubeFace.b, CubeFace.l, CubeFace.r]) {
       if (face == CubeFace.d) {
         for (int i=0; i<9; i++) {
           res.add(MapEntry(face, i));
         }
       } else {
         for (int i=3; i<9; i++) {
           res.add(MapEntry(face, i));
         }
       }
    }
    return res;
  }

  List<MapEntry<CubeFace, int>> _getStage3Stickers() {
    final res = _get2x2x3Stickers();
    // Add oriented edges (top face stickers to show orientation)
    res.addAll([
      const MapEntry(CubeFace.u, 1), const MapEntry(CubeFace.u, 3),
      const MapEntry(CubeFace.u, 5), const MapEntry(CubeFace.u, 7),
      const MapEntry(CubeFace.b, 3), // BR edge
      const MapEntry(CubeFace.d, 5), // DR edge
    ]);
    return res;
  }
}
