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
    int? ollSubIndex,
    int? pllSubIndex,
    int? f2lSubIndex,
  })? onDemoRequested;
  final void Function(int index, {int? ollSubIndex, int? pllSubIndex, int? f2lSubIndex})? onTabChanged;
  final int initialOllSubIndex;
  final int initialPllSubIndex;
  final int initialF2lSubIndex;

  const CfopGuideScreen({
    super.key,
    this.initialExpandedStepIndex = -1,
    this.initialScrollOffset = 0.0,
    this.initialOllSubIndex = 0,
    this.initialPllSubIndex = 0,
    this.initialF2lSubIndex = 0,
    this.onDemoRequested,
    this.onTabChanged,
  });

  @override
  State<CfopGuideScreen> createState() => _CfopGuideScreenState();
}

class _CfopGuideScreenState extends State<CfopGuideScreen>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final TabController _tabController;
  late final TabController _ollTabController;
  late final TabController _pllTabController;
  late final TabController _f2lTabController;

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

    _f2lTabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialF2lSubIndex,
    );
    _f2lTabController.addListener(_handleSubTabChange);

    _ollTabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialOllSubIndex,
    );
    _ollTabController.addListener(_handleSubTabChange);

    _pllTabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialPllSubIndex,
    );
    _pllTabController.addListener(_handleSubTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    widget.onTabChanged?.call(
      _tabController.index,
      ollSubIndex: _ollTabController.index,
      pllSubIndex: _pllTabController.index,
      f2lSubIndex: _f2lTabController.index,
    );
  }

  void _handleSubTabChange() {
    if (_f2lTabController.indexIsChanging || _ollTabController.indexIsChanging || _pllTabController.indexIsChanging) {
      return;
    }
    widget.onTabChanged?.call(
      _tabController.index,
      ollSubIndex: _ollTabController.index,
      pllSubIndex: _pllTabController.index,
      f2lSubIndex: _f2lTabController.index,
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _f2lTabController.removeListener(_handleSubTabChange);
    _ollTabController.removeListener(_handleSubTabChange);
    _pllTabController.removeListener(_handleSubTabChange);
    _tabController.dispose();
    _f2lTabController.dispose();
    _ollTabController.dispose();
    _pllTabController.dispose();
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
                        Text('CROSS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Step 2', style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
                        Text('F2L', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Step 3', style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
                        Text('OLL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Step 4', style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
                        Text('PLL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
                   _buildTabPage(_buildCrossBody()),
                   _buildTabPage(_buildF2LBody(), isScrollable: false),
                   _buildTabPage(_buildOllBody(), isScrollable: false),
                   _buildTabPage(_buildPllBody(), isScrollable: false),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _f2lTabController,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Step 2a', style: TextStyle(fontSize: 10)),
                      Text('EXTRACTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Step 2b', style: TextStyle(fontSize: 10)),
                      Text('PAIRING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _f2lTabController,
            children: [
              _buildTabPage(_buildF2LStep2a()),
              _buildTabPage(_buildF2LStep2b()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildF2LStep2a() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text(
                'F2L (First Two Layers) involves pairing each corner with its corresponding edge in the top layer and inserting them into their final position simultaneously.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(width: 16),
            _buildCubePreview(_getF2LCompleteState(), rotationX: 0.4),
          ],
        ),
        const SizedBox(height: 32),
        const Text('1. Piece Extraction', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'If pieces are in the wrong position or stuck in the middle layer, you must extract them to the top layer first.',
          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        _buildIllustration(
          'Corner Extraction',
          'Use R U R\' to bring a corner to the top layer.',
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
            onTap: () => _requestDemo(1, _getF2LCornerExtractionState(), 
              moves: [CubeMove.r, CubeMove.u, CubeMove.rPrime], 
              initialRotationX: 0.4,
              initialRotationY: 0.75,
              f2lSubIndex: 0,
            ),
          ),
        ]),
        const SizedBox(height: 32),
        _buildIllustration(
          'Edge Extraction',
          'Use R U2 R\' to extract an edge while keeping the corner on the top layer.',
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
            onTap: () => _requestDemo(1, _getF2LEdgeExtractionState(),
              moves: [CubeMove.r, CubeMove.u2, CubeMove.rPrime],
              initialRotationX: 0.4,
              initialRotationY: 0.75,
              f2lSubIndex: 0,
            ),
          ),
        ]),
        const SizedBox(height: 32),
        _buildIllustration(
          'Separating Pieces',
          'Use R U2 R\' to separate pieces that are incorrectly matched in the top layer.',
          _getF2LSeparationState(),
          rotationX: 0.4,
          rotationY: -0.75,
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
            onTap: () => _requestDemo(1, _getF2LSeparationState(),
              moves: [CubeMove.r, CubeMove.u2, CubeMove.rPrime],
              initialRotationX: 0.4,
              initialRotationY: -0.75,
              f2lSubIndex: 0,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildF2LStep2b() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Once pieces are in the top layer, use these logic cases to pair and insert them.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 32),
        _buildIllustration(
          'Case 1: White Facing Right',
          'Check if the top sticker of the edge matches the corner top color.',
          _getF2LMatchingSideState(),
          rotationX: 0.4,
          rotationY: -0.75,
        ),
        _buildDemoButtons([
          DemoOption(
            label: 'Matching Edge',
            onTap: () => _requestDemo(1, _getF2LMatchingSideState(),
              moves: [CubeMove.u, CubeMove.fPrime, CubeMove.u2, CubeMove.f, CubeMove.u2, CubeMove.fPrime, CubeMove.u, CubeMove.f],
              initialRotationX: 0.4,
              initialRotationY: -0.75,
              f2lSubIndex: 1,
            ),
          ),
          DemoOption(
            label: 'Non-Matching',
            onTap: () => _requestDemo(1, _getF2LNonMatchingSideState(),
              moves: [CubeMove.r, CubeMove.u, CubeMove.rPrime],
              initialRotationX: 0.4,
              initialRotationY: -0.75,
              f2lSubIndex: 1,
            ),
          ),
        ]),
        const SizedBox(height: 32),
        _buildIllustration(
          'Case 2: White Facing Forward',
          'This is the mirror of Case 1.',
          _getF2LMatchingFrontState(),
          rotationX: 0.4,
          rotationY: 0.75,
        ),
        _buildDemoButtons([
          DemoOption(
            label: 'Matching Edge',
            onTap: () => _requestDemo(1, _getF2LMatchingFrontState(),
              moves: [CubeMove.uPrime, CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.u2, CubeMove.r, CubeMove.uPrime, CubeMove.rPrime],
              initialRotationX: 0.4,
              initialRotationY: 0.75,
              f2lSubIndex: 1,
            ),
          ),
          DemoOption(
            label: 'Non-Matching',
            onTap: () => _requestDemo(1, _getF2LNonMatchingFrontState(),
              moves: [CubeMove.fPrime, CubeMove.uPrime, CubeMove.f],
              initialRotationX: 0.4,
              initialRotationY: 0.75,
              f2lSubIndex: 1,
            ),
          ),
        ]),
        const SizedBox(height: 32),
        _buildIllustration(
          'Case 3: White Facing Up',
          'Requires a setup move to rotate the edge to match its side color.',
          _getF2LTopState(),
          rotationX: 0.4,
          rotationY: 0.75,
        ),
        _buildDemoButtons([
          DemoOption(
            label: 'Show Case 3 Demo',
            onTap: () => _requestDemo(1, _getF2LTopState(),
              moves: [CubeMove.uPrime, CubeMove.fPrime, CubeMove.u2, CubeMove.f, CubeMove.uPrime, CubeMove.fPrime, CubeMove.u, CubeMove.f],
              initialRotationX: 0.4,
              initialRotationY: 0.75,
              f2lSubIndex: 1,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildAlgorithmDetail(String alg, {int? ollSubIndex}) {
    final moves = _parseAlg(alg);
    final state = CubeState.yellowTopSolved().applyMoves(moves.map((m) => m.inverse).toList().reversed.toList());
    
    return Row(
      children: [
        _buildCubePreview(state, rotationX: 0.4),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(alg, style: const TextStyle(color: Colors.white54, fontFamily: 'monospace', fontSize: 13)),
              const SizedBox(height: 12),
              _buildShowMeButton(
                label: 'Show Demo',
                color: const Color(0xFF6366F1),
                onPressed: () => _requestDemo(2, state, moves: moves, initialRotationX: 0.4, ollSubIndex: ollSubIndex),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOllBody() {
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
              controller: _ollTabController,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Step 3a', style: TextStyle(fontSize: 10)),
                      Text('ORIENT CROSS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Step 3b', style: TextStyle(fontSize: 10)),
                      Text('ORIENT CORNERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _ollTabController,
            children: [
              _buildTabPage(_buildOllStep3a()),
              _buildTabPage(_buildOllStep3b()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOllStep3a() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phase 1: Orient any remaining yellow edges on the top layer to create a cross. You will see either 0 or 2 edges already oriented.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        _buildIllustration('1. Dot Case (0 Edges)', 'No yellow edges are oriented on the top layer.', _getOllCrossDotState()),
        const SizedBox(height: 12),
        _buildAlgorithmDetail("F R U R' U' F' U2 F U R U' R' F'", ollSubIndex: 0),
        const SizedBox(height: 32),
        _buildIllustration('2. L-Shape Case (2 Edges)', 'Two adjacent yellow edges are oriented.', _getOllCrossAngleState()),
        const SizedBox(height: 12),
        _buildAlgorithmDetail("F U R U' R' F'", ollSubIndex: 0),
        const SizedBox(height: 32),
        _buildIllustration('3. Line Case (2 Edges)', 'Two opposite yellow edges are oriented.', _getOllCrossBarState()),
        const SizedBox(height: 12),
        _buildAlgorithmDetail("F R U R' U' F'", ollSubIndex: 0),
        const SizedBox(height: 24),
        const Text(
          'Note: If you have an odd number of oriented edges (1 or 3), your cube has a parity error or a twisted piece.',
          style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildOllStep3b() {
    final crossCases = AlgLibrary.ollCases.where((alg) => alg.subcategory == 'Cross').toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phase 2: Use algorithm patterns to orient the remaining corners and complete the yellow face.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        
        _buildOllCornerGroup('0 Corners Oriented', 
          crossCases.where((c) => c.id == 'oll21' || c.id == 'oll22').toList()),
        
        const SizedBox(height: 32),
        _buildOllCornerGroup('1 Corner Oriented', 
          crossCases.where((c) => c.id == 'oll26' || c.id == 'oll27').toList()),
          
        const SizedBox(height: 32),
        _buildOllCornerGroup('2 Corners Oriented', 
          crossCases.where((c) => c.id == 'oll23' || c.id == 'oll24' || c.id == 'oll25').toList()),
      ],
    );
  }

  Widget _buildOllCornerGroup(String title, List<AlgCase> cases) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.grid_view_rounded, color: Color(0xFF6366F1), size: 16),
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        ...cases.map((alg) {
          final state = _getOllCornerState(alg.id);
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
                Row(
                  children: [
                    Text(alg.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(alg.id.replaceFirst('oll_', '').toUpperCase(),
                        style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildCubePreview(state, rotationX: 0.4),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alg.algorithm, 
                            style: const TextStyle(color: Colors.white54, fontFamily: 'monospace', fontSize: 12),
                            softWrap: true,
                          ),
                          const SizedBox(height: 12),
                          _buildShowMeButton(
                            label: 'View Demo',
                            color: const Color(0xFF6366F1),
                            onPressed: () => _requestDemo(2, state, moves: alg.algorithmMoves, initialRotationX: 0.4, ollSubIndex: 1),
                          ),
                        ],
                      ),
                    ),
                   ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPllBody() {
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
              controller: _pllTabController,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Step 4a', style: TextStyle(fontSize: 10)),
                      Text('CORNERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Step 4b', style: TextStyle(fontSize: 10)),
                      Text('EDGES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _pllTabController,
            children: [
              _buildTabPage(_buildPllStep4a()),
              _buildTabPage(_buildPllStep4b()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPllStep4a() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phase 1: Look for "Headlights" (two corners of the same color on one side).',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        _buildPllCornerStep('1. Headlights Found', 
          'Put headlights in the back and do Aa-Perm.', 
          'pll_aa', 
          "R' F R' B2 R F' R' B2 R2",
          pllSubIndex: 0
        ),
        const SizedBox(height: 24),
        _buildPllCornerStep('2. No Headlights', 
          'Do Y-Perm from any angle, then you will have headlights.', 
          'pll_y', 
          "F R U' R' U' R U R' F' R U R' U' R' F R F'",
          pllSubIndex: 0
        ),
      ],
    );
  }

  Widget _buildPllStep4b() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phase 2: Now that corners are solved, use one of these 4 algorithms to finish the cube.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        _buildPllEdgeGrid(pllSubIndex: 1),
      ],
    );
  }

  Widget _buildPllCornerStep(String title, String desc, String algId, String notation, {int? pllSubIndex}) {
    final state = _getPllState(algId);
    final moves = _parseAlg(notation);
    
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
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildCubePreview(state, rotationX: 0.4),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notation, style: const TextStyle(color: Colors.white54, fontFamily: 'monospace', fontSize: 13)),
                    const SizedBox(height: 12),
                    _buildShowMeButton(
                      label: 'Show Demo',
                      color: const Color(0xFF6366F1),
                      onPressed: () => _requestDemo(3, state, moves: moves, initialRotationX: 0.4, pllSubIndex: pllSubIndex),
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

  Widget _buildPllEdgeGrid({int? pllSubIndex}) {
    return GridView.count(
      crossAxisCount: 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      childAspectRatio: 2.2,
      children: AlgLibrary.pllCases.where((c) => c.id.startsWith('pll_u')).toList().asMap().entries.map((e) {
        final algCase = e.value;
        final state = _getPllState(algCase.id);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              _buildCubePreview(state, rotationX: 0.4),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(algCase.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(algCase.algorithm, style: const TextStyle(color: Colors.white54, fontFamily: 'monospace', fontSize: 11), softWrap: true),
                    const SizedBox(height: 12),
                    _buildShowMeButton(
                      label: 'Show Demo',
                      color: const Color(0xFF6366F1),
                      onPressed: () => _requestDemo(3, state, moves: algCase.algorithmMoves, initialRotationX: 0.4, pllSubIndex: pllSubIndex),
                    ),
                  ],
                ),
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
    int? ollSubIndex,
    int? pllSubIndex,
    int? f2lSubIndex,
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
      scrollOffset: _scrollController.hasClients ? _scrollController.offset : 0.0,
      ollSubIndex: ollSubIndex ?? _ollTabController.index,
      pllSubIndex: pllSubIndex ?? _pllTabController.index,
      f2lSubIndex: f2lSubIndex ?? _f2lTabController.index,
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

  // ── State Generators ──────────────────────────────────────────────────────

  CubeState _getF2LCompleteState() {
    final state = CubeState.yellowTopSolved();
    return state.applyMoves([
      CubeMove.r, CubeMove.u, CubeMove.rPrime, CubeMove.uPrime,
      CubeMove.rPrime, CubeMove.f, CubeMove.r2, CubeMove.uPrime,
      CubeMove.rPrime, CubeMove.uPrime, CubeMove.r, CubeMove.u,
      CubeMove.rPrime, CubeMove.fPrime
    ]);
  }

  CubeState _getScrambledBaseState() {
    final state = CubeState.yellowTopSolved();
    final noise = [CubeMove.u, CubeMove.u];
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

  CubeState _getOllCrossDotState() {
    final state = CubeState.yellowTopSolved().applyMoves(_parseAlg("F R U R' U' F' U2 F U R U' R' F'"));
    return _forceF2LSolved(_clearTopCorners(state));
  }

  CubeState _getOllCrossAngleState() {
    final state = CubeState.yellowTopSolved().applyMoves(_parseAlg("F R U R' U' F'"));
    return _forceF2LSolved(_clearTopCorners(state));
  }

  CubeState _getOllCrossBarState() {
    final state = CubeState.yellowTopSolved().applyMoves(_parseAlg("F U R U' R' F'"));
    return _forceF2LSolved(_clearTopCorners(state));
  }

  CubeState _getOllCornerState(String algId) {
    final state = CubeState.yellowTopSolved();
    final setupState = state.applyMoves(AlgLibrary.ollCases.firstWhere((a) => a.id == algId).setupMoveList);
    return _forceF2LSolved(setupState);
  }

  CubeState _getPllState(String algId) {
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
    for (int i = 0; i < 9; i++) {
       state.d[i] = CubeColor.white;
    }
    for (int i = 3; i < 9; i++) {
      state.f[i] = CubeColor.green;
      state.b[i] = CubeColor.blue;
      state.l[i] = CubeColor.red;
      state.r[i] = CubeColor.orange;
    }
    return state;
  }

  CubeState _getF2LCornerExtractionState() {
    final state = CubeState.yellowTopSolved();
    state.f[8] = CubeColor.white;
    state.r[6] = CubeColor.orange;
    state.d[2] = CubeColor.green;
    state.u[1] = CubeColor.orange; 
    state.b[1] = CubeColor.green;
    return state;
  }

  CubeState _getF2LEdgeExtractionState() {
    final state = CubeState.yellowTopSolved();
    state.f[5] = CubeColor.orange;
    state.r[3] = CubeColor.green;
    state.u[8] = CubeColor.green;
    state.f[2] = CubeColor.orange;
    state.r[0] = CubeColor.white;
    state.d[2] = CubeColor.red; 
    return state;
  }

  CubeState _getF2LMatchingSideState() {
    final state = CubeState.yellowTopSolved();
    state.f[5] = CubeColor.red; state.r[3] = CubeColor.red;
    state.f[8] = CubeColor.red; state.r[6] = CubeColor.red; state.d[2] = CubeColor.yellow;
    state.u[8] = CubeColor.orange;
    state.f[2] = CubeColor.green;
    state.r[0] = CubeColor.white;
    state.u[1] = CubeColor.orange;
    state.b[1] = CubeColor.green; 
    return state;
  }

  CubeState _getF2LNonMatchingSideState() {
    final state = CubeState.yellowTopSolved();
    state.f[5] = CubeColor.red;
    state.r[3] = CubeColor.red;
    state.f[8] = CubeColor.red;
    state.r[6] = CubeColor.red;
    state.d[2] = CubeColor.yellow;
    state.u[8] = CubeColor.orange;
    state.f[2] = CubeColor.green;
    state.r[0] = CubeColor.white;
    state.u[1] = CubeColor.green;
    state.b[1] = CubeColor.orange;
    return state;
  }

  CubeState _getF2LTopState() {
    final state = CubeState.yellowTopSolved();
    state.f[5] = CubeColor.red; state.r[3] = CubeColor.red;
    state.f[8] = CubeColor.red; state.r[6] = CubeColor.red; state.d[2] = CubeColor.yellow;
    state.u[8] = CubeColor.white;
    state.f[2] = CubeColor.orange;
    state.r[0] = CubeColor.green;
    state.u[3] = CubeColor.orange;
    state.l[1] = CubeColor.green;
    return state;
  }

  CubeState _getF2LMatchingFrontState() {
    final state = CubeState.yellowTopSolved();
    state.f[5] = CubeColor.red; state.r[3] = CubeColor.red;
    state.f[8] = CubeColor.red; state.r[6] = CubeColor.red; state.d[2] = CubeColor.yellow;
    state.u[8] = CubeColor.green;
    state.f[2] = CubeColor.white;
    state.r[0] = CubeColor.orange;
    state.u[1] = CubeColor.green;
    state.b[1] = CubeColor.orange;
    return state;
  }

  CubeState _getF2LNonMatchingFrontState() {
    final state = CubeState.yellowTopSolved();
    state.f[5] = CubeColor.red; state.r[3] = CubeColor.red;
    state.f[8] = CubeColor.red; state.r[6] = CubeColor.red; state.d[2] = CubeColor.yellow;
    state.u[8] = CubeColor.green;
    state.f[2] = CubeColor.white;
    state.r[0] = CubeColor.orange;
    state.u[3] = CubeColor.orange;
    state.l[1] = CubeColor.green;
    return state;
  }

  CubeState _getF2LSeparationState() {
    final state = CubeState.yellowTopSolved();
    state.f[5] = CubeColor.red; state.r[3] = CubeColor.red;
    state.f[8] = CubeColor.red; state.r[6] = CubeColor.red; state.d[2] = CubeColor.yellow;
    state.u[8] = CubeColor.green;
    state.f[2] = CubeColor.orange;
    state.r[0] = CubeColor.white;
    state.u[5] = CubeColor.orange;
    state.r[1] = CubeColor.green;
    return state;
  }

  List<CubeMove> _parseAlg(String notation) {
    if (notation.trim().isEmpty) return [];
    final cleaned = notation.replaceAll('(', '').replaceAll(')', '');
    return cleaned
        .trim()
        .split(RegExp(r'\s+'))
        .map((s) => CubeMove.parse(s))
        .whereType<CubeMove>()
        .toList();
  }
}
