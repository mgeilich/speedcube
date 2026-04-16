import 'package:flutter/material.dart';
import 'cube_renderer.dart';
import '../models/cube_state.dart';
import '../models/cube_move.dart';

class DemoOption {
  final String label;
  final VoidCallback onTap;

  const DemoOption({required this.label, required this.onTap});
}

/// Interactive guide for the ZZ method.
class ZzGuideScreen extends StatefulWidget {
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

  const ZzGuideScreen({
    super.key,
    this.initialExpandedStepIndex = -1,
    this.initialScrollOffset = 0.0,
    this.onDemoRequested,
    this.onTabChanged,
  });

  @override
  State<ZzGuideScreen> createState() => _ZzGuideScreenState();
}

class _ZzGuideScreenState extends State<ZzGuideScreen>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _scrollController =
        ScrollController(initialScrollOffset: widget.initialScrollOffset);
    _tabController = TabController(
      length: 4,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF0F0F25),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'ZZ Tutorial',
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
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelPadding: const EdgeInsets.symmetric(vertical: 8),
                tabs: const [
                  Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Step 1', style: TextStyle(fontSize: 10)),
                        Text('EOLine', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Step 2', style: TextStyle(fontSize: 10)),
                        Text('Left', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Step 3', style: TextStyle(fontSize: 10)),
                        Text('Right', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Step 4', style: TextStyle(fontSize: 10)),
                        Text('LL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTabPage(_buildEOLineBody()),
            _buildTabPage(_buildLeftBlockBody()),
            _buildTabPage(_buildRightBlockBody()),
            _buildTabPage(_buildLLBody()),
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

  Widget _buildEOLineBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stage 1: EOLine',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'EOLine is the heart of the ZZ method. You solve two things at once: orient all 12 edges and solve the Front and Back bottom edges.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 32),
        _buildSectionHeader('1. Understanding Edge Orientation'),
        const Text(
          'A "bad edge" is one that requires an F or B move to solve. In ZZ, we fix all bad edges right at the start!',
          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        _buildIllustration(
          'Good vs Bad Edges',
          'Highlighting all oriented edges in ZZ.',
          _getBadEdgeState(),
          highlightedStickers: _getOrientedStickers(),
          dimNonHighlighted: true,
          rotationX: 0.4,
          rotationY: 0.6,
        ),
        const SizedBox(height: 32),
        _buildSectionHeader('2. Solving the Line'),
        const Text(
          'Once edges are oriented, solve the White-Green (DF) and White-Blue (DB) edges to form a line on the bottom.',
          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
        ),
        _buildIllustration(
          'The ZZ Line',
          'White-Green at front, White-Blue at back.',
          _getEOLineSolvedState(),
          highlightedStickers: [
            const MapEntry(CubeFace.d, 1), const MapEntry(CubeFace.f, 7),
            const MapEntry(CubeFace.d, 7), const MapEntry(CubeFace.b, 7),
          ],
          dimNonHighlighted: true,
          rotationX: -0.4,
          rotationY: 0.6,
        ),
      ],
    );
  }

  Widget _buildLeftBlockBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stage 2: Left Block',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Because all edges are now oriented, you can solve the entire left 1x2x3 block using ONLY <U, L, R> moves. No rotations allowed!',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 32),
        _buildIllustration(
          'Left 1x2x3 Block',
          'Completed left side of the block.',
          _getLeftBlockSolvedState(),
          highlightedStickers: _getLeftBlockStickers(),
          dimNonHighlighted: true,
          rotationX: 0.4,
          rotationY: 0.8,
        ),
        const SizedBox(height: 24),
        _buildDemoButtons([
          DemoOption(
            label: 'Show Left Block Build',
            onTap: () => _requestDemo(1, _getLeftBlockDemoState(), moves: [CubeMove.u, CubeMove.lPrime, CubeMove.uPrime, CubeMove.l]),
          ),
        ]),
      ],
    );
  }

  Widget _buildRightBlockBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         const Text(
          'Stage 3: Right Block',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Finish the F2L by building the right 1x2x3 block. Again, only <U, L, R> moves are needed.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 32),
        _buildIllustration(
          'Right 1x2x3 Block',
          'Completed right side block.',
          _getRightBlockSolvedState(),
          highlightedStickers: _getRightBlockStickers(),
          dimNonHighlighted: true,
          rotationX: 0.4,
          rotationY: -0.8,
        ),
      ],
    );
  }

  Widget _buildLLBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stage 4: Last Layer',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Since all edges are oriented, you ALWAYS have a cross on top! This makes the Last Layer much simpler.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 32),
        const Text('OCLL: Orient corners using Sune/Anti-Sune.'),
        const Text('PLL: Permute alles using standard algorithms.'),
      ],
    );
  }

  // --- HELPERS ---

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
            width: 150,
            height: 150,
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)),
            child: CustomPaint(
              painter: CubeRenderer(
                cubeState: state, 
                rotationX: rotationX, 
                rotationY: rotationY,
                highlightedStickers: highlightedStickers,
                dimNonHighlighted: dimNonHighlighted,
              ),
              size: const Size(120, 120),
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
              backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              foregroundColor: const Color(0xFF8B5CF6),
              side: const BorderSide(color: Color(0xFF8B5CF6), width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: opt.onTap,
            child: Text(opt.label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      )).toList(),
    );
  }

  void _requestDemo(int stepIndex, CubeState initialState, {List<CubeMove>? moves}) {
    widget.onDemoRequested?.call(stepIndex, initialState, moves: moves);
  }

  // --- REAL STATES FOR DEMOS ---

  /// Returns a state with several bad edges highlighted (conceptually)
  CubeState _getBadEdgeState() {
    // Apply some moves that flip edges
    return CubeState.solved().applyMoves(_parseAlg("F R B L"));
  }

  /// Returns a state where exactly the EOLine is solved
  CubeState _getEOLineSolvedState() {
    // Need a scramble, then apply the solver's EO result (simulated for tutorial)
    var s = CubeState.solved();
    // Orientation is already Good, just place DF/DB
    return s; 
  }

  /// Returns a state with a 1x2x3 block on the left
  CubeState _getLeftBlockSolvedState() {
    // White on Bottom (D), Green on Front (F), Red on Left (L)
    // LB pieces: DL, FL, BL edges + DFL, DBL corners
    final s = CubeState.solved();
    // In a solved state, these are already solved.
    return s;
  }

  CubeState _getLeftBlockDemoState() {
    // Scrambled except for EOLine, ready to solve LB
    return CubeState.solved().applyMoves(_parseAlg("U L U' L'"));
  }

  CubeState _getRightBlockSolvedState() {
    return CubeState.solved();
  }

  List<MapEntry<CubeFace, int>> _getOrientedStickers() {
    return [
      const MapEntry(CubeFace.u, 1), const MapEntry(CubeFace.u, 3), const MapEntry(CubeFace.u, 5), const MapEntry(CubeFace.u, 7),
      const MapEntry(CubeFace.d, 1), const MapEntry(CubeFace.d, 3), const MapEntry(CubeFace.d, 5), const MapEntry(CubeFace.d, 7),
      const MapEntry(CubeFace.f, 3), const MapEntry(CubeFace.f, 5), const MapEntry(CubeFace.b, 3), const MapEntry(CubeFace.b, 5),
    ];
  }

  List<MapEntry<CubeFace, int>> _getLeftBlockStickers() {
    final List<MapEntry<CubeFace, int>> res = [];
    // L face (all)
    for (int i = 0; i < 9; i++) {
        res.add(MapEntry(CubeFace.l, i));
    }
    // D [0,3,6], F [3,6], B [5,8]
    res.addAll([
        const MapEntry(CubeFace.d, 0), const MapEntry(CubeFace.d, 3), const MapEntry(CubeFace.d, 6),
        const MapEntry(CubeFace.f, 3), const MapEntry(CubeFace.f, 6),
        const MapEntry(CubeFace.b, 5), const MapEntry(CubeFace.b, 8),
    ]);
    return res;
  }

  List<MapEntry<CubeFace, int>> _getRightBlockStickers() {
    final List<MapEntry<CubeFace, int>> res = [];
    // R face (all)
    for (int i = 0; i < 9; i++) {
        res.add(MapEntry(CubeFace.r, i));
    }
    // D [2,5,8], F [5,8], B [3,6]
    res.addAll([
        const MapEntry(CubeFace.d, 2), const MapEntry(CubeFace.d, 5), const MapEntry(CubeFace.d, 8),
        const MapEntry(CubeFace.f, 5), const MapEntry(CubeFace.f, 8),
        const MapEntry(CubeFace.b, 3), const MapEntry(CubeFace.b, 6),
    ]);
    return res;
  }

  List<CubeMove> _parseAlg(String alg) {
     return alg.split(' ').map((m) => CubeMove.parse(m)).whereType<CubeMove>().toList();
  }
}
