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

/// Interactive guide for the Roux method.
class RouxGuideScreen extends StatefulWidget {
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
    int? cmllSubIndex,
    int? lseSubIndex,
  })? onDemoRequested;
  final void Function(int index, {int? cmllSubIndex, int? lseSubIndex})? onTabChanged;
  final int initialCmllSubIndex;
  final int initialLseSubIndex;

  const RouxGuideScreen({
    super.key,
    this.initialExpandedStepIndex = -1,
    this.initialScrollOffset = 0.0,
    this.initialCmllSubIndex = 0,
    this.initialLseSubIndex = 0,
    this.onDemoRequested,
    this.onTabChanged,
  });

  @override
  State<RouxGuideScreen> createState() => _RouxGuideScreenState();
}

class _RouxGuideScreenState extends State<RouxGuideScreen>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final TabController _tabController;
  late final TabController _cmllTabController;
  late final TabController _lseTabController;

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

    _cmllTabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialCmllSubIndex,
    );
    _cmllTabController.addListener(_handleSubTabChange);

    _lseTabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialLseSubIndex,
    );
    _lseTabController.addListener(_handleSubTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    widget.onTabChanged?.call(
      _tabController.index,
      cmllSubIndex: _cmllTabController.index,
      lseSubIndex: _lseTabController.index,
    );
  }

  void _handleSubTabChange() {
    if (_cmllTabController.indexIsChanging || _lseTabController.indexIsChanging) {
      return;
    }
    widget.onTabChanged?.call(
      _tabController.index,
      cmllSubIndex: _cmllTabController.index,
      lseSubIndex: _lseTabController.index,
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _cmllTabController.removeListener(_handleSubTabChange);
    _lseTabController.removeListener(_handleSubTabChange);
    _tabController.dispose();
    _cmllTabController.dispose();
    _lseTabController.dispose();
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Roux Tutorial',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
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
                  color: const Color(0xFF6366F1),
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
                        Text('Step 1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
                        Text('FB', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Step 2', style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
                        Text('SB', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Step 3', style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
                        Text('CMLL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Step 4', style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
                        Text('LSE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                   _buildTabPage(_buildFirstBlockBody()),
                   _buildTabPage(_buildSecondBlockBody(), isScrollable: false),
                   _buildTabPage(_buildCmllBody(), isScrollable: false),
                   _buildTabPage(_buildLseBody(), isScrollable: false),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildTabPage(Widget body, {bool isScrollable = true}) {
    if (!isScrollable) {
      return body;
    }
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: body,
    );
  }

  Widget _buildFirstBlockBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text(
                'First Block (FB): Build a 1x2x3 block on the left side of the cube. This is the most intuitive part of Roux.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(width: 16),
            _buildCubePreview(_getFBCompleteState(), rotationX: 0.4, rotationY: -0.6),
          ],
        ),
        const SizedBox(height: 32),
        const Text('1. The DL Edge', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'The anchor of your first block is the DL edge. Position it on the bottom face, aligned with the left center.',
          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
        ),
        _buildIllustration(
          'DL Edge Anchor',
          'Position the Red-White edge on the bottom-left.',
          _getDLEdgeState(),
          rotationX: -0.4,
          rotationY: -0.6,
          highlightedStickers: [
            MapEntry(CubeFace.l, 7),
            MapEntry(CubeFace.d, 3),
          ],
        ),
        const SizedBox(height: 32),
        const Text('2. Build the Square', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'Pair a corner with an edge to form a 1x2x2 square. For example, the DLB corner with the BL edge.',
          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
        ),
        _buildIllustration(
          'Left Square',
          '1x2x2 block in the back-left.',
          _getFBSquareState(),
          rotationX: 0.4,
          rotationY: -1.2,
        ),
        _buildDemoButtons([
          DemoOption(
            label: 'Show Square Build',
            onTap: () => _requestDemo(0, _getDLEdgeState(), 
              moves: [CubeMove.u, CubeMove.lPrime, CubeMove.uPrime, CubeMove.l],
              initialRotationX: 0.4,
              initialRotationY: -1.2,
            ),
          ),
        ]),
        const SizedBox(height: 32),
        const Text('3. Complete the 1x2x3', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'Add the remaining pieces (FL edge and DLF corner) to finish the block.',
          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSecondBlockBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Text(
            'Second Block (SB): Build a 1x2x3 block on the right side. Rule: use only R, r, U, and M moves so you do not break the First Block.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ),
        _buildIllustration(
          'Second Block Goal',
          '1x2x3 block on the right (Orange side).',
          _getSBCompleteState(),
          rotationX: 0.4,
          rotationY: 0.6,
        ),
        const SizedBox(height: 24),
        _buildDemoButtons([
          DemoOption(
            label: 'Show Second Block Demo',
            onTap: () => _requestDemo(1, _getFBCompleteState(),
              moves: [CubeMove.parse("R")!, CubeMove.parse("U")!, CubeMove.parse("R'")!, CubeMove.parse("M'")!, CubeMove.parse("U")!, CubeMove.parse("R")!],
              initialRotationX: 0.4,
              initialRotationY: 0.6,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildCmllBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _cmllTabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                 Tab(
                  child: Text('BASIC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                Tab(
                  child: Text('ADVANCED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _cmllTabController,
            children: [
              _buildTabPage(_buildCmllBasicBody()),
              _buildTabPage(_buildCmllAdvancedBody()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCmllBasicBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CMLL: Corners of the Last Layer. Solve both orientation and permutation of the 4 top corners. The 2 layers are ignored.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        _buildCmllCase('Sune', "R U R' U R U2 R'", _getCmllSuneState()),
        _buildCmllCase('Anti-Sune', "R U2 R' U' R U' R'", _getCmllAntiSuneState()),
      ],
    );
  }

  Widget _buildCmllAdvancedBody() {
    final cmllCases = AlgLibrary.cmllCases;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...cmllCases.take(5).map((alg) => _buildCmllCase(alg.name, alg.algorithm, _getAlgState(alg))),
      ],
    );
  }

  Widget _buildCmllCase(String name, String alg, CubeState state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
               _buildCubePreview(state, rotationX: 0.4),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(alg, style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace')),
                     const SizedBox(height: 12),
                     _buildShowMeButton(
                       label: 'View Demo',
                       color: const Color(0xFF6366F1),
                       onPressed: () => _requestDemo(2, state, moves: _parseAlg(alg), initialRotationX: 0.4),
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

  Widget _buildLseBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _lseTabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                 Tab(child: Text('4A: EO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                 Tab(child: Text('4B: UL/UR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                 Tab(child: Text('4C: MID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _lseTabController,
            children: [
              _buildTabPage(_buildLse4a()),
              _buildTabPage(_buildLse4b()),
              _buildTabPage(_buildLse4c()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLse4a() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '4A: Edge Orientation (EO). Use M and U moves to orient the remaining 6 edges so that they can be solved with only M and U2 moves.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        _buildLseEOAlgorithm('4-Edge Flip', "M' U M' U M' U M'", _getLse4EdgeFlipState()),
        _buildLseEOAlgorithm('All 6 Flip', "M' U M' U M' U2 M' U M' U M' U2", _getLse6EdgeFlipState()),
      ],
    );
  }

  Widget _buildLseEOAlgorithm(String name, String alg, CubeState state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Text(alg, style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace')),
          const SizedBox(height: 12),
          _buildShowMeButton(
            label: 'Show EO Demo',
            onPressed: () => _requestDemo(3, state, moves: _parseAlg(alg), initialRotationX: 0.4, lseSubIndex: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildLse4b() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '4B: Solve the UL and UR edges. These are the edges that belong at the Upper-Left and Upper-Right positions.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        SizedBox(height: 24),
        Text(
          'Once EO is complete, these edges can be moved to the top layer and positioned using M2 and U moves.',
          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }
  
  Widget _buildLse4c() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '4C: Solve the remaining 4 M-slice edges. At this point, only M and U2 moves are needed.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  // Helper methodologies

  Widget _buildCubePreview(CubeState state, {double rotationX = 0, double rotationY = 0}) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: CubeRenderer(
          cubeState: state,
          rotationX: rotationX,
          rotationY: rotationY,
        ),
        size: const Size(80, 80),
      ),
    );
  }

  Widget _buildIllustration(String title, String subtitle, CubeState state, {double rotationX = 0, double rotationY = 0, List<MapEntry<CubeFace, int>>? highlightedStickers}) {
     // TODO: Implement highlighted stickers in CubeRenderer or similar
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         const SizedBox(height: 16),
         Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
         const SizedBox(height: 4),
         Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
         const SizedBox(height: 12),
         Center(child: _buildCubePreview(state, rotationX: rotationX, rotationY: rotationY)),
       ],
     );
  }

  Widget _buildDemoButtons(List<DemoOption> options) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: options.map((opt) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildShowMeButton(label: opt.label, onPressed: opt.onTap),
        )).toList(),
      ),
    );
  }

  Widget _buildShowMeButton({required String label, required VoidCallback onPressed, Color color = const Color(0xFF6366F1)}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_outline, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _requestDemo(int stepIndex, CubeState state, {List<CubeMove>? moves, double? initialRotationX, double? initialRotationY, int? cmllSubIndex, int? lseSubIndex}) {
    widget.onDemoRequested?.call(
      stepIndex,
      state,
      moves: moves,
      initialRotationX: initialRotationX,
      initialRotationY: initialRotationY,
      scrollOffset: _scrollController.hasClients ? _scrollController.offset : 0,
      cmllSubIndex: cmllSubIndex,
      lseSubIndex: lseSubIndex,
    );
  }

  List<CubeMove> _parseAlg(String alg) {
    return alg.split(' ').map((s) => CubeMove.parse(s)).whereType<CubeMove>().toList();
  }

  // --- State Definitions ---

  CubeState _getFBCompleteState() {
     return CubeState.yellowTopSolved().applyMoves(_parseAlg("L' U L U L' U2 L U' L' U L")); 
  }

  CubeState _getSBCompleteState() {
     return _getFBCompleteState().applyMoves(_parseAlg("R U R' U' R U2 R'"));
  }

  CubeState _getDLEdgeState() {
    final s = CubeState.yellowTopSolved();
    // Scramble everything but DL edge
    return s.applyMoves(_parseAlg("R U F B R' U' F' B' R U")); 
  }

  CubeState _getFBSquareState() {
     return _getDLEdgeState().applyMoves(_parseAlg("L' U L"));
  }

  CubeState _getCmllSuneState() {
     return _getSBCompleteState().applyMoves(_parseAlg("R U R' U R U2 R'").map((m) => m.inverse).toList().reversed.toList());
  }

  CubeState _getCmllAntiSuneState() {
     return _getSBCompleteState().applyMoves(_parseAlg("R U2 R' U' R U' R'").map((m) => m.inverse).toList().reversed.toList());
  }

  CubeState _getLse4EdgeFlipState() {
     return CubeState.solved().applyMoves(_parseAlg("M' U M' U M' U M'").map((m) => m.inverse).toList().reversed.toList());
  }

  CubeState _getLse6EdgeFlipState() {
     return CubeState.solved().applyMoves(_parseAlg("M' U M' U M' U2 M' U M' U M' U2").map((m) => m.inverse).toList().reversed.toList());
  }

  CubeState _getAlgState(AlgCase alg) {
     return CubeState.solved().applyMoves(alg.setupMoveList);
  }
}
