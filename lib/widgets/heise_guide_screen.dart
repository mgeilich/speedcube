import 'package:flutter/material.dart';
import 'cube_renderer.dart';
import '../models/cube_state.dart';
import '../models/cube_move.dart';

class DemoOption {
  final String label;
  final VoidCallback onTap;

  const DemoOption({required this.label, required this.onTap});
}

/// Interactive guide for the Heise method.
class HeiseGuideScreen extends StatefulWidget {
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
    Map<int, String>? moveLabels,
  })? onDemoRequested;
  final void Function(int index)? onTabChanged;

  const HeiseGuideScreen({
    super.key,
    this.initialExpandedStepIndex = -1,
    this.initialScrollOffset = 0.0,
    this.onDemoRequested,
    this.onTabChanged,
  });

  @override
  State<HeiseGuideScreen> createState() => _HeiseGuideScreenState();
}

class _HeiseGuideScreenState extends State<HeiseGuideScreen> with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: widget.initialScrollOffset);
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: widget.initialExpandedStepIndex != -1 ? widget.initialExpandedStepIndex : 0,
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Heise Tutorial', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: '2x2x2'),
                Tab(text: '2x2x3'),
                Tab(text: 'Squares'),
                Tab(text: 'EO'),
                Tab(text: 'Edges'),
                Tab(text: 'Comm.'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabPage(_build2x2x2Body()),
          _buildTabPage(_build2x2x3Body()),
          _buildTabPage(_buildSquaresBody()),
          _buildTabPage(_buildEOBody()),
          _buildTabPage(_buildEdgesBody()),
          _buildTabPage(_buildCommBody()),
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

  Widget _build2x2x2Body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Stage 1: The 2x2x2 Block', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Build a 2x2x2 block anywhere. Standard orientation uses the Back-Down-Left (DBL) corner.', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 32),
        _buildIllustration('2x2x2 Block', 'One corner and three edges solved.', CubeState.solved(), highlightedStickers: _get2x2x2Stickers(), dimNonHighlighted: true, rotationX: 0.4, rotationY: 0.8),
      ],
    );
  }

  Widget _build2x2x3Body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Stage 2: Expand to 2x2x3', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Extend your block into a 2x2x3. This leaves only two faces free to rotate (usually U and R).', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 32),
        _buildIllustration('2x2x3 Block', 'Expanding the 2x2x2 to the front.', CubeState.solved(), highlightedStickers: _get2x2x3Stickers(), dimNonHighlighted: true, rotationX: 0.4, rotationY: 0.8),
      ],
    );
  }

  Widget _buildSquaresBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Stage 3: Two Squares', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Build two 1x2 squares on the remaining faces. This is the most intuitive part of Heise.', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildEOBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Stage 4: Edge Orientation', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Orient all remaining edges. This simplifies the final placement of pieces.', style: TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  Widget _buildEdgesBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Stage 5: Edges & Two Corners', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Solve all edges and two more corners. This leaves exactly three corners unsolved.', style: TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  Widget _buildCommBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Stage 6: The Commutator', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('The final 3 corners are solved using a commutator: A B A\' B\'.', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildDemoButtons([
          DemoOption(
            label: 'Show Commutator (A B A\' B\')',
            onTap: () => _requestCommutatorDemo(),
          ),
        ]),
        const SizedBox(height: 32),
        _buildIllustration(
          'Target Pieces',
          'Corners labeled 1, 2, and 3 for the cycle.',
          CubeState.solved(),
          stickerLabels: {
            CubeFace.u: {6: '1', 8: '2'},
            CubeFace.d: {2: '3'},
          },
          rotationX: 0.4,
          rotationY: 0.6,
        ),
      ],
    );
  }

  void _requestCommutatorDemo() {
    // Standard Niklas commutator as an example: R U' L' U R' U' L U
    final moves = [
      CubeMove(CubeFace.r, 1), CubeMove(CubeFace.u, -1),
      CubeMove(CubeFace.l, -1), CubeMove(CubeFace.u, 1),
      CubeMove(CubeFace.r, -1), CubeMove(CubeFace.u, -1),
      CubeMove(CubeFace.l, 1), CubeMove(CubeFace.u, 1),
    ];
    
    final moveLabels = {
      0: 'A', 1: 'B', 2: 'A\'', 3: 'B\'',
      4: 'A', 5: 'B', 6: 'A\'', 7: 'B\'',
    };

    widget.onDemoRequested?.call(
      5, 
      CubeState.solved().applyMoves(moves.reversed.map((m) => CubeMove(m.face, -m.turns)).toList()),
      moves: moves,
      moveLabels: moveLabels,
      stickerLabels: {
        CubeFace.u: {0: '1', 2: '2'},
        CubeFace.f: {0: '3'},
      }
    );
  }

  // --- Helpers ---

  Widget _buildIllustration(String title, String subtitle, CubeState state, 
      {double rotationX = 0, double rotationY = 0, List<MapEntry<CubeFace, int>>? highlightedStickers, bool dimNonHighlighted = false, Map<CubeFace, Map<int, String>>? stickerLabels}) {
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
                stickerLabels: stickerLabels,
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
              backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              foregroundColor: const Color(0xFFF59E0B),
              side: const BorderSide(color: Color(0xFFF59E0B), width: 1),
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

  List<MapEntry<CubeFace, int>> _get2x2x2Stickers() {
    return [
      const MapEntry(CubeFace.l, 0), const MapEntry(CubeFace.l, 3), const MapEntry(CubeFace.l, 6),
      const MapEntry(CubeFace.l, 1), const MapEntry(CubeFace.l, 4), const MapEntry(CubeFace.l, 7),
      const MapEntry(CubeFace.d, 0), const MapEntry(CubeFace.d, 3), const MapEntry(CubeFace.d, 6),
      const MapEntry(CubeFace.b, 2), const MapEntry(CubeFace.b, 5), const MapEntry(CubeFace.b, 8),
    ];
  }

  List<MapEntry<CubeFace, int>> _get2x2x3Stickers() {
    final res = _get2x2x2Stickers();
    res.addAll([
      const MapEntry(CubeFace.f, 0), const MapEntry(CubeFace.f, 3), const MapEntry(CubeFace.f, 6),
      const MapEntry(CubeFace.u, 6), const MapEntry(CubeFace.u, 3), const MapEntry(CubeFace.u, 0),
    ]);
    return res;
  }
}
