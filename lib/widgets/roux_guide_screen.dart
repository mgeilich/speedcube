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
            _buildCubePreview(_getFBCompleteState(), rotationX: 0.4, rotationY: 0.6),
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
          rotationY: 0.6,
          highlightedStickers: [
            MapEntry(CubeFace.l, 7),
            MapEntry(CubeFace.d, 3),
          ],
        ),
        const SizedBox(height: 32),
        const Text('2. Build the Square', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'Pair a corner with an edge to form a 1x2x2 square. For example, the DLF corner with the FL edge.',
          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'Tip: This is just like F2L in CFOP! If you are new to pairing, check out the CFOP tutorial for details.',
            style: TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),
        _buildIllustration(
          'Left Square',
          '1x2x2 block in the front-left.',
          _getFBSquareState(),
          rotationX: 0.4,
          rotationY: 0.8,
        ),
        _buildDemoButtons([
          DemoOption(
            label: 'Show Square Build',
            onTap: () => _requestDemo(0, _getSquareBuildDemoState(), 
              moves: [CubeMove.uPrime, CubeMove.lPrime, CubeMove.u, CubeMove.l],
              initialRotationX: 0.4,
              initialRotationY: 0.8,
            ),
          ),
        ]),
        const SizedBox(height: 32),
        const Text('3. Complete the 1x2x3', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'Add the remaining pieces (BL edge and DLB corner) to finish the block.',
          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
        ),
        _buildIllustration(
          'Target: First 1x2x3 Block',
          'Completed left side of the cube.',
          _getFBCompleteState(),
          highlightedStickers: _getLeftBlockStickers(),
          dimNonHighlighted: true,
          rotationY: 0.8,
        ),
        _buildDemoButtons([
          DemoOption(
            label: 'Show 1x2x3 Completion',
            onTap: () => _requestDemo(0, _getFBCompleteDemoState(),
              moves: [CubeMove.u, CubeMove.lPrime, CubeMove.uPrime, CubeMove.l],
              initialRotationX: 0.4,
              initialRotationY: 0.8,
            ),
          ),
        ]),
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
            onTap: () => _requestDemo(1, _getSBBuildDemoState(),
              moves: [CubeMove.uPrime, CubeMove.r, CubeMove.u, CubeMove.rPrime],
              initialRotationX: 0.4,
              initialRotationY: -0.6, // Rotate to see the right side
            ),
          ),
        ]),
        const SizedBox(height: 32),
        _buildMSliceMastery(isIntroduction: true),
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
          'CMLL: Corners of the Last Layer. This is a 2-step process in the Basic method: Orientation (getting the top color right) and Permutation (moving corners to their final spots).',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        const Text(
          'Step 1: Orientation (CO)',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Goal: Get all 4 corners showing the top face color (usually Yellow). Note: The bottom layers should remain solved.',
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Beginner Tip: "Orientation First"',
                style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 6),
              Text(
                'If you don\'t have exactly 1 yellow corner facing up: Rotate the top layer (U move) and apply the Sune algorithm. If you still don\'t have exactly 1, rotate the top layer again and retry! Rotating changes the starting position of the corners, allowing the same algorithm to produce a different result until you reach the "fish" pattern. (Count only the 4 corners, ignore the center sticker).',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildCmllCase(
          'Sune', 
          "R U R' U R U2 R'", 
          _getCmllSuneState(),
          description: 'Single corner solved (Fish). Place it in the bottom-left. The front face should have a yellow sticker at the top-right.',
        ),
        _buildCmllCase(
          'Anti-Sune', 
          "R U2 R' U' R U' R'", 
          _getCmllAntiSuneState(),
          description: 'Single corner solved (Fish). Place it in the top-right. The front face should have a yellow sticker at the top-left.',
        ),
        const SizedBox(height: 32),
        const Text(
          'Step 2: Permutation (CP)', 
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Goal: Swap the corners into their correct positions. Even if the top face is all one color, the corners might still be in the wrong spots!',
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 16),
        _buildCmllCase(
          'Jb-Perm (Adjacent Swap)', 
          "R U R' F' R U R' U' R' F R2 U' R'", 
          _getAlgState(AlgLibrary.cmll.firstWhere((c) => c.id == 'pll_jb' || c.id == 'cmll_o_adj')),
          description: 'Look for "Headlights" (two matching colors on one side). Place the headlights on the LEFT and apply this algorithm.',
        ),
        _buildCmllCase(
          'Y-Perm (Diagonal Swap)', 
          "F R U' R' U' R U R' F' R U R' U' R' F R F'", 
          _getAlgState(AlgLibrary.all.firstWhere((c) => c.id == 'pll_y')),
          description: 'If you have NO matching side colors on any face, apply this algorithm from any angle to swap diagonal corners.',
        ),
      ],
    );
  }

  Widget _buildCmllAdvancedBody() {
    final cmllCases = AlgLibrary.cmllCases;
    // Group cases by subcategory
    final Map<String, List<AlgCase>> grouped = {};
    for (var c in cmllCases) {
      grouped.putIfAbsent(c.subcategory, () => []).add(c);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'In full CMLL, you solve orientation AND permutation in one step. There are 42 cases total.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          _buildCmllInfoSection(
            'How to Identify Cases',
            'First, identify the Orientation (the top yellow pattern: H, Pi, Sune, etc.). Then, look at the colors on the sides of the corners to find matching patterns like "Headlights" or "Bars".',
            icon: Icons.search_rounded,
          ),
          const SizedBox(height: 12),
          _buildCmllInfoSection(
            'The Fallback (2-Step Method)',
            'If you don\'t know the specific algorithm for a case, use the Basic method: \n1. Orient (CO) using Sune until all corners are yellow on top.\n2. Permute (CP) using J-Perm or Y-Perm to move them to the right spots.',
            icon: Icons.lightbulb_outline_rounded,
          ),
          const SizedBox(height: 32),
          const Text('Featured Advanced Cases', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),

          ...grouped.entries.map((entry) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Case ${entry.key}',
                  style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              ...entry.value.map((alg) => _buildCmllCase(alg.name, alg.algorithm, _getAlgState(alg), description: alg.description)),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildCmllCase(String name, String alg, CubeState state, {String? description}) {
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
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.4)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
               _buildCubePreview(state, rotationX: 0.4, rotationY: 0.6),
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
                       onPressed: () => _requestDemo(2, state, moves: _parseAlg(alg), initialRotationX: 0.4, initialRotationY: 0.6),
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
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 0, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Starting Point:',
                style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'Both side blocks (1x2x3) and all 4 corners are solved. Side blocks should be on the Left (Red) and Right (Orange) sides.',
                style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        Container(
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
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _lseTabController,
            children: [
              _buildTabPage(Column(
                children: [
                   _buildLse4a(),
                   const SizedBox(height: 32),
                   _buildMSliceMastery(isIntroduction: false),
                ],
              )),
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
        _buildLseEOAlgorithm('4-Edge Flip (Top Layer)', "M' U M' U M' U M'", _getLse4EdgeFlipState()),
        _buildLseEOAlgorithm('2-Edge Flip (Front/Back)', "M' U M' U2 M' U M'", _getLse2EdgeFlipAdjState()),
        _buildLseEOAlgorithm('2-Edge Flip (Top/Bottom)', "M' U M' U' M' U M'", _getLse2EdgeFlipOppState()),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '4B: Solve the UL and UR edges. These are the edges that belong at the Upper-Left and Upper-Right positions.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        const Text(
          'Goal: Move the UL/UR edges to their final spots on the left and right sides of the top layer.',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Once EO is complete, you can solve these edges using only M2 and U moves. Usually, you move both edges to the bottom (DF/DB) and then use M2 to insert them into the top layer.',
          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        _buildShowMeButton(
          label: 'View UL/UR Demo',
          onPressed: () => _requestDemo(3, _getLse4bDemoState(), moves: _parseAlg("U' M2 U M2"), initialRotationX: 0.4, lseSubIndex: 1),
        ),
      ],
    );
  }
  
  Widget _buildLse4c() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '4C: Solve the remaining 4 M-slice edges. At this point, only M and U2 moves are needed.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        const Text(
          'The Final Step!',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'You just need to permute the UF, UB, DF, and DB edges. Common cases include the dots (two M2 U2 cycles) and parallel swaps.',
          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        _buildShowMeButton(
          label: 'View M-Slice Demo',
          onPressed: () => _requestDemo(3, _getLse4cDemoState(), moves: _parseAlg("M2 U2 M2"), initialRotationX: 0.4, lseSubIndex: 2),
        ),
      ],
    );
  }

  // Helper methodologies

  Widget _buildCubePreview(CubeState state, {double rotationX = 0, double rotationY = 0, List<MapEntry<CubeFace, int>>? highlightedStickers, bool dimNonHighlighted = false}) {
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
          highlightedStickers: highlightedStickers,
          dimNonHighlighted: dimNonHighlighted,
        ),
        size: const Size(80, 80),
      ),
    );
  }

  Widget _buildIllustration(String title, String subtitle, CubeState state, {double rotationX = 0, double rotationY = 0, List<MapEntry<CubeFace, int>>? highlightedStickers, bool dimNonHighlighted = false}) {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         const SizedBox(height: 16),
         Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
         const SizedBox(height: 4),
         Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
         const SizedBox(height: 12),
         Center(child: _buildCubePreview(state, rotationX: rotationX, rotationY: rotationY, highlightedStickers: highlightedStickers, dimNonHighlighted: dimNonHighlighted)),
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

  Widget _buildMSliceMastery({bool isIntroduction = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.15),
            const Color(0xFF8B5CF6).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: Color(0xFF6366F1), size: 24),
              SizedBox(width: 12),
              Text(
                'M-Slice Mastery',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMSliceTip(
            'The Secret Logic',
            isIntroduction 
              ? 'An M\' move is exactly like doing (r R\'). You move the middle slice UP while keeping the side pieces still. Think of it as "Side-Block Preservation".'
              : 'In LSE, the side blocks are locked. Every move you make should be an M or U move. This keeps the blocks safe while you flip and permute edges.',
            icon: Icons.psychology_rounded,
          ),
          const SizedBox(height: 16),
          const Text(
            'Fingertrick Techniques:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 12),
          _buildFingertrickItem("M' (Upward)", "Use your LEFT RING finger to push the bottom-back edge (DB) up towards the back (UB). This is the fastest Roux move."),
          _buildFingertrickItem("M (Downward)", "Place your index finger on the top-front edge (UF) and pull it down towards the bottom (DF)."),
          _buildFingertrickItem("M2 (Double Flick)", "Push with your ring finger, followed immediately by your middle finger. Think of it as a 'snapping' motion."),
          const SizedBox(height: 20),
          _buildShowMeButton(
            label: 'Demo M vs M\'',
            onPressed: () => _requestDemo(
              isIntroduction ? 1 : 3, 
              CubeState.solved(), 
              moves: [CubeMove.mPrime, CubeMove.u2, CubeMove.m, CubeMove.u2],
              initialRotationX: 0.4,
              initialRotationY: 0.6,
            ),
            color: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildMSliceTip(String title, String content, {required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF6366F1).withValues(alpha: 0.7), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(content, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFingertrickItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCmllInfoSection(String title, String content, {required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6366F1), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
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
    // Solved 1x2x3 block on the left side (Red face)
    // We achieve this by taking a solved cube and scrambling only the R, U, and M layers.
    return CubeState.yellowTopSolved().applyMoves(_parseAlg("R U R' U' R U2 R' M U M' U2 M U M'"));
  }

  CubeState _getSBCompleteState() {
     // Both FB and SB complete. Top layer and M-slice edges are not yet solved.
     // We scramble M and U to show that only the side blocks matter.
     return CubeState.yellowTopSolved().applyMoves(_parseAlg("M U M' U2 M' U M")); 
  }

  CubeState _getSBBuildDemoState() {
     // Setup for SB final pair insertion (into the back-right slot)
     // Start with the SB complete and pull the last pair out.
     return _getSBCompleteState().applyMoves(_parseAlg("R U' R' U"));
  }

  CubeState _getDLEdgeState() {
    final s = CubeState.yellowTopSolved();
    // Scramble everything EXCEPT the DL edge (Red-White)
    return s.applyMoves(_parseAlg("R U F B R' U' F' B' R U")); 
  }

  CubeState _getFBSquareState() {
     // Solved 1x2x2 square on the front-left (DL + FL + DLF)
     // Start with FB complete and break only the Back-Left bar (BL + DLB)
     // Using a more thorough scramble for the back part.
     return _getFBCompleteState().applyMoves(_parseAlg("B2 U B2 U' B2")); 
  }

  CubeState _getSquareBuildDemoState() {
     // Setup for a 4-move insertion of the Front-Left square (U' L' U L)
     // Start with just the DL edge solved (and scrambled back part)
     return _getFBSquareState().applyMoves(_parseAlg("L' U' L U"));
  }

  CubeState _getFBCompleteDemoState() {
     // Setup for a 4-move insertion of the Back-Left bar (U L' U' L)
     // Start with the 1x2x2 square solved.
     return _getFBCompleteState().applyMoves(_parseAlg("L' U L U'"));
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

  CubeState _getLse2EdgeFlipAdjState() {
     return CubeState.solved().applyMoves(_parseAlg("M' U M' U2 M' U M'").map((m) => m.inverse).toList().reversed.toList());
  }

  CubeState _getLse2EdgeFlipOppState() {
     return CubeState.solved().applyMoves(_parseAlg("M' U M' U' M' U M'").map((m) => m.inverse).toList().reversed.toList());
  }

  CubeState _getLse4bDemoState() {
     // Setup for UL (Yellow-Red) and UR (Yellow-Orange) solution: U' M2 U M2
     // Start from solved and apply inverse of the demo moves
     return CubeState.solved().applyMoves(_parseAlg("M2 U' M2 U"));
  }

  CubeState _getLse4cDemoState() {
     // Setup for dots case: M2 U2 M2
     return CubeState.solved().applyMoves(_parseAlg("M2 U2 M2"));
  }

  CubeState _getAlgState(AlgCase alg) {
     // For CMLL, start from a state with both blocks complete.
     return _getSBCompleteState().applyMoves(alg.setupMoveList);
  }

  List<MapEntry<CubeFace, int>> _getLeftBlockStickers() {
    final List<MapEntry<CubeFace, int>> res = [];
    for (int i = 0; i < 9; i++) {
      res.add(MapEntry(CubeFace.l, i));
    }
    res.addAll([
        const MapEntry(CubeFace.d, 0), const MapEntry(CubeFace.d, 3), const MapEntry(CubeFace.d, 6),
        const MapEntry(CubeFace.f, 3), const MapEntry(CubeFace.f, 6),
        const MapEntry(CubeFace.b, 5), const MapEntry(CubeFace.b, 8),
    ]);
    return res;
  }


}
