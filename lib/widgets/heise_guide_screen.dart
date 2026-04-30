import 'package:flutter/material.dart';
import 'cube_renderer.dart';
import '../models/cube_state.dart';
import '../models/cube_move.dart';
import '../models/solve_result.dart';
import '../solver/heise_solver.dart';

class DemoOption {
  final String label;
  final VoidCallback onTap;

  const DemoOption({required this.label, required this.onTap});
}

/// Interactive guide for the Heise method.
class HeiseGuideScreen extends StatefulWidget {
  static void clearCache() {
    _HeiseGuideScreenState._cachedSolveResult = null;
    _HeiseGuideScreenState._cachedScrambledState = null;
  }

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
  
  static LblSolveResult? _cachedSolveResult;
  static CubeState? _cachedScrambledState;
  
  bool _isSolving = false;
  String? _solveError;

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
    
    if (_cachedSolveResult == null) {
      _generateAndSolve();
    }
  }

  Future<void> _generateAndSolve() async {
    setState(() {
      _isSolving = true;
      _solveError = null;
    });

    try {
      final scramble = CubeState.generateScramble(20);
      final state = CubeState.solved().applyMoves(scramble);
      final result = await HeiseSolver.solve(state);
      
      if (result.steps.isEmpty) {
        throw Exception("Solver failed to find a solution.");
      }

      if (mounted) {
        setState(() {
          _cachedScrambledState = state;
          _cachedSolveResult = result;
          _isSolving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSolving = false;
          _solveError = e.toString();
        });
      }
    }
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
        const Text('Build a 2x2x2 block anywhere. The most common approach is building it around the Down-Back-Left (DBL) corner.', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 32),
        _buildIllustration(
          '2x2x2 Block (DBL)', 
          'The corner and three adjacent edges are solved.', 
          CubeState.solved(), 
          highlightedStickers: _get2x2x2Stickers(), 
          dimNonHighlighted: true, 
          rotationX: 0.4, 
          rotationY: 0.8
        ),
        const SizedBox(height: 24),
        _buildDemoSection("2x2x2 Block", "Watch 2x2x2 Demo"),
      ],
    );
  }

  Widget _build2x2x3Body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Stage 2: Expand to 2x2x3', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Extend your block into a 2x2x3. This typically involves adding the Down-Front-Left pieces, leaving only two faces free to rotate (U and R).', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 32),
        _buildIllustration(
          '2x2x3 Block (Left Side)', 
          'Expanding the 2x2x2 toward the front.', 
          CubeState.solved(), 
          highlightedStickers: _get2x2x3Stickers(), 
          dimNonHighlighted: true, 
          rotationX: 0.4, 
          rotationY: 0.8
        ),
        const SizedBox(height: 24),
        _buildDemoSection("2x2x3 Block", "Watch 2x2x3 Demo"),
      ],
    );
  }

  Widget _buildSquaresBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Stage 3: Two Squares', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Build two 1x2 squares on the remaining faces (Front and Right). This is the most intuitive part of Heise.', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 32),
        _buildIllustration(
          'Two Squares', 
          'Leaving only 5 edges and 5 corners unsolved.', 
          CubeState.solved(), 
          highlightedStickers: _getTwoSquaresStickers(), 
          dimNonHighlighted: true, 
          rotationX: 0.4, 
          rotationY: -0.6
        ),
        const SizedBox(height: 24),
        _buildDemoSection("Two Squares", "Watch Squares Demo"),
      ],
    );
  }

  Widget _buildEOBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Stage 4: Edge Orientation', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Orient all remaining edges. This simplifies the final placement of pieces and prevents parity issues.', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 32),
        _buildIllustration(
          'Edge Orientation', 
          'All edges correctly oriented relative to Top/Bottom.', 
          CubeState.solved(), 
          highlightedStickers: _getEOStickers(), 
          dimNonHighlighted: true, 
          rotationX: 0.5, 
          rotationY: -0.5
        ),
        const SizedBox(height: 24),
        _buildDemoSection("Edge Orientation", "Watch EO Demo"),
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
        const SizedBox(height: 32),
        _buildIllustration(
          'Edges and Two Corners', 
          'Leaving a 3-corner commutator finish.', 
          CubeState.solved(), 
          highlightedStickers: _getStage5Stickers(), 
          dimNonHighlighted: true, 
          rotationX: 0.5, 
          rotationY: -0.5
        ),
        const SizedBox(height: 24),
        _buildDemoSection("Two Pairs & Edges", "Watch Edges Demo"),
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
        const SizedBox(height: 24),
        _buildDemoSection("The Commutator Finish", "Watch Commutator Demo"),
      ],
    );
  }

  void _requestStageDemo(String stageName) {
    if (_cachedSolveResult == null || _cachedScrambledState == null) return;

    CubeState stateBefore = _cachedScrambledState!;
    List<CubeMove>? moves;
    Map<int, String>? moveLabels;

    for (final step in _cachedSolveResult!.steps) {
      if (step.stageName == stageName) {
        moves = step.moves;
        
        if (stageName == "The Commutator Finish" && moves.length >= 8) {
           moveLabels = {
            0: 'A', 1: 'B', 2: 'A\'', 3: 'B\'',
            4: 'A', 5: 'B', 6: 'A\'', 7: 'B\'',
          };
        }
        break;
      }
      stateBefore = stateBefore.applyMoves(step.moves);
    }

    if (moves == null) return;

    widget.onDemoRequested?.call(
      _tabController.index,
      stateBefore,
      moves: moves,
      moveLabels: moveLabels,
    );
  }

  Widget _buildDemoSection(String stageName, String buttonLabel) {
    if (_isSolving) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: const Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B))),
            SizedBox(width: 12),
            Text('Generating demo solve...', style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      );
    }

    if (_solveError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Could not generate demo: $_solveError', style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _generateAndSolve,
            icon: const Icon(Icons.refresh, size: 16, color: Color(0xFFF59E0B)),
            label: const Text('Retry Demo Generation', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    final hasStage = _cachedSolveResult?.steps.any((s) => s.stageName == stageName) ?? false;
    if (!hasStage) return const SizedBox.shrink();

    return _buildDemoButtons([
      DemoOption(
        label: buttonLabel,
        onTap: () => _requestStageDemo(stageName),
      ),
    ]);
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
      // Left face (bottom back quadrant)
      const MapEntry(CubeFace.l, 3), const MapEntry(CubeFace.l, 4),
      const MapEntry(CubeFace.l, 6), const MapEntry(CubeFace.l, 7),
      // Down face (back left quadrant)
      const MapEntry(CubeFace.d, 3), const MapEntry(CubeFace.d, 4),
      const MapEntry(CubeFace.d, 6), const MapEntry(CubeFace.d, 7),
      // Back face (down left quadrant)
      const MapEntry(CubeFace.b, 4), const MapEntry(CubeFace.b, 5),
      const MapEntry(CubeFace.b, 7), const MapEntry(CubeFace.b, 8),
    ];
  }

  List<MapEntry<CubeFace, int>> _get2x2x3Stickers() {
    final res = _get2x2x2Stickers();
    res.addAll([
      // Front face expansion
      const MapEntry(CubeFace.f, 3), const MapEntry(CubeFace.f, 4),
      const MapEntry(CubeFace.f, 6), const MapEntry(CubeFace.f, 7),
      // Extra Left stickers
      const MapEntry(CubeFace.l, 5), const MapEntry(CubeFace.l, 8),
      // Extra Down stickers
      const MapEntry(CubeFace.d, 0), const MapEntry(CubeFace.d, 1),
    ]);
    return res;
  }

  List<MapEntry<CubeFace, int>> _getTwoSquaresStickers() {
    final res = _get2x2x3Stickers();
    res.addAll([
      // Front-Down-Right square
      const MapEntry(CubeFace.f, 5), const MapEntry(CubeFace.f, 8),
      const MapEntry(CubeFace.r, 6), const MapEntry(CubeFace.r, 7),
      const MapEntry(CubeFace.d, 2), const MapEntry(CubeFace.d, 5),
      // Back-Down-Right square
      const MapEntry(CubeFace.b, 3), const MapEntry(CubeFace.b, 6),
      const MapEntry(CubeFace.r, 5), const MapEntry(CubeFace.r, 8),
      const MapEntry(CubeFace.d, 8),
    ]);
    return res;
  }

  List<MapEntry<CubeFace, int>> _getEOStickers() {
    // Show all stickers from Stage 3 plus all edges highlighted
    final res = _getTwoSquaresStickers();
    // Top edges
    res.addAll([
      const MapEntry(CubeFace.u, 1), const MapEntry(CubeFace.u, 3),
      const MapEntry(CubeFace.u, 5), const MapEntry(CubeFace.u, 7),
      const MapEntry(CubeFace.f, 1), const MapEntry(CubeFace.r, 1),
      const MapEntry(CubeFace.b, 1), const MapEntry(CubeFace.l, 1),
    ]);
    return res;
  }

  List<MapEntry<CubeFace, int>> _getStage5Stickers() {
    // Everything except 3 corners (e.g., UFL, UFR, UBR)
    final res = <MapEntry<CubeFace, int>>[];
    for (final face in CubeFace.physicalFaces) {
      for (int i = 0; i < 9; i++) {
        // Skip some top corners
        if (face == CubeFace.u && (i == 0 || i == 2 || i == 8)) continue;
        if (face == CubeFace.l && i == 0) continue;
        if (face == CubeFace.f && i == 2) continue;
        if (face == CubeFace.r && i == 2) continue;
        res.add(MapEntry(face, i));
      }
    }
    return res;
  }
}
