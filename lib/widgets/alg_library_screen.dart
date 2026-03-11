import 'package:flutter/material.dart';
import '../models/alg_library.dart';
import '../models/cube_move.dart';
import '../models/cube_state.dart';
import '../animation/cube_animation_controller.dart';
import '../utils/premium_manager.dart';
import 'cube_renderer.dart';

/// Full-screen algorithm library browser (OLL + PLL)
class AlgLibraryScreen extends StatefulWidget {
  const AlgLibraryScreen({super.key});

  @override
  State<AlgLibraryScreen> createState() => _AlgLibraryScreenState();
}

class _AlgLibraryScreenState extends State<AlgLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AlgGuideSheet(),
    );
  }

  void _openCase(AlgCase algCase) {
    final isPremium = PremiumManager().isPremium;
    if (!algCase.isFree && !isPremium) {
      _showPremiumGate();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AlgDetailSheet(algCase: algCase),
    );
  }

  void _showPremiumGate() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(Icons.lock_rounded, color: Color(0xFF6366F1), size: 48),
            const SizedBox(height: 16),
            const Text(
              'Premium Feature',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unlock all First Two Layers, Orient Last Layer and Permute Last Layer algorithms with SpeedCube AR Premium.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await PremiumManager().buyPremium();
                  if (mounted) {
                    Navigator.pop(context);
                    setState(() {});
                  }
                },
                child: const Text('Upgrade to Premium',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Algorithm Library',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white70),
            onPressed: _showGuide,
            tooltip: 'How to use',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'First Two Layers  (${AlgLibrary.f2lCases.length})'),
            Tab(text: 'Orient Last Layer  (57)'),
            Tab(text: 'Permute Last Layer  (21)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AlgGrid(cases: AlgLibrary.f2l, onTap: _openCase),
          _AlgGrid(cases: AlgLibrary.oll, onTap: _openCase),
          _AlgGrid(cases: AlgLibrary.pll, onTap: _openCase),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid view with subcategory headers
// ─────────────────────────────────────────────────────────────────────────────

class _AlgGrid extends StatelessWidget {
  final List<AlgCase> cases;
  final void Function(AlgCase) onTap;

  const _AlgGrid({required this.cases, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Group by subcategory, preserving order
    final groups = <String, List<AlgCase>>{};
    for (final c in cases) {
      groups.putIfAbsent(c.subcategory, () => []).add(c);
    }

    final isPremium = PremiumManager().isPremium;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final subcategory = groups.keys.elementAt(i);
        final group = groups[subcategory]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child: Text(
                subcategory.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            // Grid of cards
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemCount: group.length,
              itemBuilder: (context, j) {
                final algCase = group[j];
                final locked = !algCase.isFree && !isPremium;
                return _AlgCaseCard(
                  algCase: algCase,
                  locked: locked,
                  onTap: () => onTap(algCase),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual case card with mini top-layer diagram
// ─────────────────────────────────────────────────────────────────────────────

class _AlgCaseCard extends StatelessWidget {
  final AlgCase algCase;
  final bool locked;
  final VoidCallback onTap;

  const _AlgCaseCard({
    required this.algCase,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: locked ? 0.38 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: locked ? const Color(0xFF111122) : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: locked
                  ? Colors.white10
                  : const Color(0xFF6366F1).withValues(alpha: 0.35),
              width: locked ? 1 : 1.5,
            ),
            boxShadow: locked
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ],
          ),
          child: Stack(
            children: [
              // Content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: _MiniTopDiagram(algCase: algCase),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      algCase.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              // Lock overlay (only for locked cards)
              if (locked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_rounded,
                        color: Color(0xFF818CF8),
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini top-layer diagram painter
// Shows the U face (3×3) + top strip of F/R/B/L
// ─────────────────────────────────────────────────────────────────────────────

class _MiniTopDiagram extends StatelessWidget {
  final AlgCase algCase;

  const _MiniTopDiagram({required this.algCase});

  @override
  Widget build(BuildContext context) {
    final state = CubeState.yellowTopSolved().applyMoves(algCase.setupMoveList);
    return CustomPaint(
      size: const Size(52, 52),
      painter: _TopDiagramPainter(state, algCase.category),
    );
  }
}

class _TopDiagramPainter extends CustomPainter {
  final CubeState state;
  final AlgCategory category;
  _TopDiagramPainter(this.state, this.category);

  Color _getColor(CubeColor c) {
    // For OLL, only yellow stickers matter. Non-yellow should be dark.
    if (category == AlgCategory.oll && c != CubeColor.yellow) {
      return const Color(0xFF333344);
    }
    switch (c) {
      case CubeColor.white:
        return Colors.white;
      case CubeColor.yellow:
        return const Color(0xFFFFD600);
      case CubeColor.green:
        return const Color(0xFF00C853);
      case CubeColor.blue:
        return const Color(0xFF2196F3);
      case CubeColor.red:
        return const Color(0xFFE53935);
      case CubeColor.orange:
        return const Color(0xFFFF6D00);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 3x3 center face + thin strips on sides
    // Center face is the middle 80% of the area
    final sideStripSize = size.width * 0.16;
    final centerArea = size.width - (sideStripSize * 2);
    final cellSize = centerArea / 3;

    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black54
      ..strokeWidth = 0.5;

    void drawCell(Rect rect, CubeColor color) {
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(1.5));
      paint.color = _getColor(color);
      canvas.drawRRect(rrect, paint);
      canvas.drawRRect(rrect, borderPaint);
    }

    // U face (3×3)
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        drawCell(
          Rect.fromLTWH(
            sideStripSize + col * cellSize + 0.5,
            sideStripSize + row * cellSize + 0.5,
            cellSize - 1,
            cellSize - 1,
          ),
          state.u[row * 3 + col],
        );
      }
    }

    // F face top row (indices 0,1,2) → bottom strip
    for (int col = 0; col < 3; col++) {
      drawCell(
        Rect.fromLTWH(
          sideStripSize + col * cellSize + 0.5,
          sideStripSize + centerArea + 2, // 2px gap
          cellSize - 1,
          sideStripSize - 3,
        ),
        state.f[col],
      );
    }

    // B face top row (indices 0,1,2) → top strip (row 0), reversed
    for (int col = 0; col < 3; col++) {
      drawCell(
        Rect.fromLTWH(
          sideStripSize + (2 - col) * cellSize + 0.5,
          1, // Top
          cellSize - 1,
          sideStripSize - 3,
        ),
        state.b[col],
      );
    }

    // L face left column (indices 0,3,6) → left strip
    for (int row = 0; row < 3; row++) {
      drawCell(
        Rect.fromLTWH(
          1, // Left
          sideStripSize + row * cellSize + 0.5,
          sideStripSize - 3,
          cellSize - 1,
        ),
        state.l[row * 3],
      );
    }

    // R face right column (indices 2,5,8) → right strip
    for (int row = 0; row < 3; row++) {
      drawCell(
        Rect.fromLTWH(
          sideStripSize + centerArea + 2, // Right
          sideStripSize + row * cellSize + 0.5,
          sideStripSize - 3,
          cellSize - 1,
        ),
        state.r[row * 3 + 2],
      );
    }
  }

  @override
  bool shouldRepaint(_TopDiagramPainter old) =>
      old.state != state || old.category != category;
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AlgDetailSheet extends StatefulWidget {
  final AlgCase algCase;
  const _AlgDetailSheet({required this.algCase});

  @override
  State<_AlgDetailSheet> createState() => _AlgDetailSheetState();
}

class _AlgDetailSheetState extends State<_AlgDetailSheet>
    with SingleTickerProviderStateMixin {
  late CubeAnimationController _animController;
  late CubeState _cubeState;
  bool _isAnimating = false;
  int _highlightedMove = -1;
  int _animGeneration = 0;

  // Rotation state for drag-to-rotate
  double _rotationX = 0.45;
  double _rotationY = 0.5;
  Offset? _lastPanPosition;

  @override
  void initState() {
    super.initState();
    _animController = CubeAnimationController(
      vsync: this,
      moveDuration: const Duration(milliseconds: 450),
      onUpdate: () => setState(() {}),
      onMoveComplete: _onMoveComplete,
    );
    _resetToCase();
  }

  void _resetToCase() {
    _animGeneration++;
    _animController.clearQueue();
    setState(() {
      _cubeState = (widget.algCase.category == AlgCategory.f2l
              ? CubeState.solved()
              : CubeState.yellowTopSolved())
          .applyMoves(widget.algCase.setupMoveList);
      _isAnimating = false;
      _highlightedMove = -1;
    });
  }

  void _onMoveComplete() {
    if (_animController.currentMove != null) {
      setState(() {
        _cubeState = _cubeState.applyMove(_animController.currentMove!);
      });
    }
  }

  void _animate() {
    if (_isAnimating) return;
    _animGeneration++;
    final myGen = _animGeneration;
    _animController.clearQueue();
    setState(() {
      _cubeState = (widget.algCase.category == AlgCategory.f2l
              ? CubeState.solved()
              : CubeState.yellowTopSolved())
          .applyMoves(widget.algCase.setupMoveList);
      _isAnimating = true;
      _highlightedMove = -1;
    });

    final moves = widget.algCase.algorithmMoves;
    // Play moves one at a time with highlight tracking
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _animGeneration == myGen) {
        _playStep(moves, 0, myGen);
      }
    });
  }

  void _playStep(List<CubeMove> moves, int index, int gen) {
    if (!mounted || _animGeneration != gen || index >= moves.length) {
      if (mounted && _animGeneration == gen) {
        setState(() {
          _isAnimating = false;
          _highlightedMove = -1;
        });
      }
      return;
    }
    setState(() => _highlightedMove = index);
    _animController.queueMoves([moves[index]]);
    // Wait for this move's animation to finish, then proceed
    final moveDuration = const Duration(milliseconds: 450) +
        const Duration(milliseconds: 80); // slight overlap buffer
    Future.delayed(moveDuration, () {
      _playStep(moves, index + 1, gen);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moves = widget.algCase.algorithmMoves;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
            child: Row(
              children: [
                _badge(
                  widget.algCase.category == AlgCategory.f2l
                      ? 'F2L'
                      : (widget.algCase.category == AlgCategory.oll
                          ? 'OLL'
                          : 'PLL'),
                  const Color(0xFF6366F1),
                ),
                const SizedBox(width: 8),
                _badge(widget.algCase.subcategory, Colors.white24),
                const Spacer(),
                Text(
                  widget.algCase.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 3D Cube (drag to rotate)
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onPanStart: (d) => _lastPanPosition = d.localPosition,
                onPanUpdate: (d) {
                  if (_lastPanPosition != null) {
                    final delta = d.localPosition - _lastPanPosition!;
                    setState(() {
                      _rotationY += delta.dx * 0.01;
                      _rotationX += delta.dy * 0.01;
                      // Clamp vertical tilt so cube doesn't flip upside-down
                      _rotationX = _rotationX.clamp(-0.4, 1.4);
                    });
                    _lastPanPosition = d.localPosition;
                  }
                },
                onPanEnd: (_) => _lastPanPosition = null,
                child: CustomPaint(
                  painter: CubeRenderer(
                    cubeState: _cubeState,
                    rotationX: _rotationX,
                    rotationY: _rotationY,
                    animatingMove: _animController.isAnimating
                        ? _animController.currentMove
                        : null,
                    animationProgress: _animController.isAnimating
                        ? _animController.progress
                        : 0.0,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),

          // Algorithm area (scrollable if needed)
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  // Algorithm move badges
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: moves.asMap().entries.map((e) {
                        final isActive = _highlightedMove == e.key;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF6366F1).withValues(alpha: 0.85)
                                : const Color(0xFF6366F1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isActive
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFF6366F1)
                                      .withValues(alpha: 0.3),
                              width: isActive ? 2 : 1,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            e.value.toString(),
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF818CF8),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      widget.algCase.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetToCase,
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isAnimating ? null : _animate,
                    icon: Icon(
                      _isAnimating
                          ? Icons.hourglass_top_rounded
                          : Icons.play_arrow_rounded,
                      size: 20,
                    ),
                    label: Text(_isAnimating ? 'Animating…' : 'Animate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      disabledBackgroundColor:
                          const Color(0xFF6366F1).withValues(alpha: 0.4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color == const Color(0xFF6366F1)
              ? const Color(0xFF818CF8)
              : Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Guide / How-to-use bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AlgGuideSheet extends StatelessWidget {
  const _AlgGuideSheet();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.school_rounded,
                    color: Color(0xFF6366F1), size: 22),
                const SizedBox(width: 10),
                const Text(
                  'How to Use This Library',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white38, size: 22),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Scrollable content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              children: const [
                _GuideSection(
                  icon: Icons.layers_rounded,
                  color: Color(0xFF6366F1),
                  title: 'The Two Steps: OLL then PLL',
                  body:
                      'When solving the last layer of a puzzle cube, speedsolvers split it into two steps:\n\n'
                      '① OLL (Orient Last Layer) — Make the top face all one color (yellow). The pieces may not be in the right positions yet, but all their yellow stickers face up.\n\n'
                      '② PLL (Permute Last Layer) — Move the pieces to their correct positions without disturbing the orientation you just achieved.\n\n'
                      'You always do OLL first, then PLL.',
                ),
                SizedBox(height: 20),
                _GuideSection(
                  icon: Icons.search_rounded,
                  color: Color(0xFF10B981),
                  title: 'How to Identify Your OLL Case',
                  body:
                      'Look at the top face of your cube. Count how many yellow stickers are visible and note their pattern:\n\n'
                      '• Dot — only the center is yellow. No edges oriented.\n'
                      '• Cross — all 4 edges are yellow. This is the most common starting point for beginners.\n'
                      '• T-shape / L-shape / P-shape — 2 edges are yellow, forming that letter shape.\n'
                      '• I-shape / C-shape / W-shape / Z-shape — 2 opposite edges, in various corner patterns.\n'
                      '• Corners Only — all 4 edges are yellow, but some corners are twisted.\n\n'
                      'Tap any case in the grid to see the exact pattern on the 3D cube.',
                ),
                SizedBox(height: 20),
                _GuideSection(
                  icon: Icons.swap_horiz_rounded,
                  color: Color(0xFFF59E0B),
                  title: 'How to Identify Your PLL Case',
                  body:
                      'After OLL, the top is all yellow. Now look at the side colors of the top layer:\n\n'
                      '• If two adjacent corners are swapped → look at J, T, R, or F-perms.\n'
                      '• If two diagonal corners are swapped → look at Y or V-perm.\n'
                      '• If only edges are cycling → look at U, Z, or H-perms.\n'
                      '• If corners AND edges are all cycling → look at G-perms.\n\n'
                      'Rotate the top layer (U moves) to find the best angle before applying the algorithm.',
                ),
                SizedBox(height: 20),
                _GuideSection(
                  icon: Icons.auto_awesome_rounded,
                  color: Color(0xFFEC4899),
                  title: 'Key Algorithm Names You\'ll See',
                  body:
                      'Many algorithms have nicknames based on their structure:\n\n'
                      '• Sune — R U R\' U R U2 R\'. The most fundamental OLL algorithm. Appears in many cases.\n\n'
                      '• Anti-Sune — the mirror/inverse of Sune. R U2 R\' U\' R U\' R\'.\n\n'
                      '• Sexy Move — R U R\' U\'. A 4-move trigger used inside many algorithms.\n\n'
                      '• Sledgehammer — R\' F R F\'. The reverse of the sexy move. Also very common.\n\n'
                      '• F-trigger — F R U R\' U\' F\'. Orients edges. Used in T-shape and Dot cases.\n\n'
                      '• B-trigger — B U R U\' R\' B\'. Same as F-trigger but on the back face.',
                ),
                SizedBox(height: 20),
                _GuideSection(
                  icon: Icons.tips_and_updates_rounded,
                  color: Color(0xFF6366F1),
                  title: 'Tips for Learning Algorithms',
                  body:
                      '① Start with the most common cases. OLL 33, 45, 26, 27 and PLL T-perm, Ua, Ub cover a huge percentage of solves.\n\n'
                      '② Tap "Animate" to watch the algorithm play out on the 3D cube. Drag the cube to see all sides.\n\n'
                      '③ Learn the shape first, then the algorithm. Being able to instantly recognize a case is half the battle.\n\n'
                      '④ Practice one new algorithm per week. Trying to learn too many at once leads to confusion.\n\n'
                      '⑤ Most algorithms have a mirror version. If you know OLL 26 (Sune), OLL 27 (Anti-Sune) is just the mirror.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _GuideSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Body text
        Text(
          body,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
      ],
    );
  }
}
