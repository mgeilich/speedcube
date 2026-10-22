import 'package:flutter/material.dart';
import '../controllers/analysis_controller.dart';
import '../models/cube_move.dart';
import '../models/cube_state.dart';
import '../models/solve_method.dart';
import '../services/solver_service.dart';
import '../utils/app_layout.dart';
import 'solve_stats_sheet.dart';

/// The method the user picked to watch, with the solution shown on its card.
typedef ComparisonPick = ({SolveMethod method, SolveResult result});

/// Solves one scramble with every method and shows the results side by side:
/// move count, stage breakdown and solve time. Tapping a card returns that
/// method and its solution so the home screen can play it back.
class MethodComparisonScreen extends StatefulWidget {
  final CubeState state;

  const MethodComparisonScreen({super.key, required this.state});

  static const methods = [
    SolveMethod.kociemba,
    SolveMethod.lbl,
    SolveMethod.cfop,
    SolveMethod.roux,
    SolveMethod.zz,
    SolveMethod.petrus,
    SolveMethod.heise,
  ];

  static String methodName(SolveMethod method) => switch (method) {
        SolveMethod.kociemba => 'Optimal (Kociemba)',
        SolveMethod.lbl => 'Layer-by-Layer',
        SolveMethod.cfop => 'CFOP',
        SolveMethod.roux => 'Roux',
        SolveMethod.zz => 'ZZ',
        SolveMethod.petrus => 'Petrus',
        SolveMethod.heise => 'Heise',
      };

  @override
  State<MethodComparisonScreen> createState() => _MethodComparisonScreenState();
}

class _MethodResult {
  SolveResult? result;
  int? elapsedMs;
  bool failed = false;

  bool get done => result != null || failed;
}

class _MethodComparisonScreenState extends State<MethodComparisonScreen> {
  final _results = {
    for (final m in MethodComparisonScreen.methods) m: _MethodResult()
  };
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _solveAll();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// One method at a time: the solvers already use background isolates, and
  /// running them together would slow every card down.
  Future<void> _solveAll() async {
    for (final method in MethodComparisonScreen.methods) {
      if (_disposed) return;
      final entry = _results[method]!;
      final sw = Stopwatch()..start();
      try {
        final result = await SolverService.solve(
          state: widget.state.clone(),
          method: method,
        );
        final solved = result.moves.isNotEmpty &&
            widget.state.applyMoves(result.moves).isSolved;
        if (solved) {
          entry.result = result;
        } else {
          entry.failed = true;
        }
      } catch (_) {
        entry.failed = true;
      }
      entry.elapsedMs = sw.elapsedMilliseconds;
      if (!_disposed) setState(() {});
    }
  }

  /// Face and slice turns; whole-cube rotations (x, y, z) aren't counted.
  static int _turnCount(List<CubeMove> moves) => moves
      .where((m) =>
          m.face != CubeFace.x && m.face != CubeFace.y && m.face != CubeFace.z)
      .length;

  /// Turn count per stage, in solve order.
  static List<({String name, int count})> _stages(SolveResult r) {
    final names = r.stageNames;
    if (names == null || names.every((n) => n == null)) {
      final p1 = _turnCount(r.moves.take(r.phase1MoveCount).toList());
      final p2 = _turnCount(r.moves.skip(r.phase1MoveCount).toList());
      return [
        if (p1 > 0) (name: 'Phase 1', count: p1),
        if (p2 > 0) (name: 'Phase 2', count: p2),
      ];
    }
    final counts = <String, int>{};
    for (int i = 0; i < r.moves.length && i < names.length; i++) {
      if (_turnCount([r.moves[i]]) == 0) continue;
      final name = AnalysisController.normalizeStage(names[i] ?? 'Kociemba');
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return [for (final e in counts.entries) (name: e.key, count: e.value)];
  }

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final e in _results.entries)
        if (e.value.result != null) e.key: _turnCount(e.value.result!.moves)
    };
    final maxCount = counts.values.fold(1, (a, b) => a > b ? a : b);
    final allDone = _results.values.every((r) => r.done);
    // Kociemba is the computer optimum and always shortest, so "fewest" is
    // awarded among the human methods; Kociemba is shown as the reference.
    final humanCounts = [
      for (final e in counts.entries)
        if (e.key != SolveMethod.kociemba) e.value
    ];
    final fewest = allDone && humanCounts.isNotEmpty
        ? humanCounts.reduce((a, b) => a < b ? a : b)
        : null;
    final wide = AppLayout.isWide(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Compare Methods',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            allDone
                ? 'Same scramble, every method. Tap one to watch it step by step.'
                : 'Solving the same scramble with every method…',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'Move counts exclude whole-cube rotations. The computer optimum '
            'is the shortest solution possible, for reference; "fewest" goes '
            'to the best human method.',
            style: TextStyle(color: Colors.white30, fontSize: 11),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final columns = wide ? 3 : (constraints.maxWidth >= 560 ? 2 : 1);
            const gap = 12.0;
            final cardWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final method in MethodComparisonScreen.methods)
                  SizedBox(
                    width: cardWidth,
                    child: _buildCard(
                      method,
                      _results[method]!,
                      maxCount,
                      isFewest: method != SolveMethod.kociemba &&
                          fewest != null &&
                          counts[method] == fewest,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCard(SolveMethod method, _MethodResult entry, int maxCount,
      {required bool isFewest}) {
    final result = entry.result;
    const accent = Color(0xFF22C55E);

    return Material(
      color: const Color(0xFF1E1E2E),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: result == null
            ? null
            : () => Navigator.pop<ComparisonPick>(
                context, (method: method, result: result)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFewest ? accent : Colors.white12,
              width: isFewest ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      MethodComparisonScreen.methodName(method),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (method == SolveMethod.kociemba)
                    const Text(
                      'COMPUTER',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  if (isFewest)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'FEWEST',
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (!entry.done)
                const Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Solving…',
                        style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                )
              else if (result == null)
                const Text("Couldn't solve this scramble",
                    style: TextStyle(color: Colors.white38, fontSize: 13))
              else
                ..._buildResult(result, entry.elapsedMs ?? 0, maxCount),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResult(SolveResult result, int elapsedMs, int maxCount) {
    final stages = _stages(result);
    final total = _turnCount(result.moves);
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          const Text('moves',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const Spacer(),
          Text(
            '${(elapsedMs / 1000).toStringAsFixed(1)} s',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
      const SizedBox(height: 10),
      // Bar length is relative to the longest solution, so cards compare.
      LayoutBuilder(builder: (context, constraints) {
        final barWidth = constraints.maxWidth * total / maxCount;
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: barWidth,
            height: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Row(
                children: [
                  for (int i = 0; i < stages.length; i++)
                    Expanded(
                      flex: stages[i].count,
                      child: Container(
                        color: SolveStatsSheet.stageColor(stages[i].name, i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 4,
        children: [
          for (int i = 0; i < stages.length; i++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: SolveStatsSheet.stageColor(stages[i].name, i),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${stages[i].name} ${stages[i].count}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
        ],
      ),
    ];
  }
}
