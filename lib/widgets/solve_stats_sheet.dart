import 'package:flutter/material.dart';
import '../controllers/analysis_controller.dart';
import '../utils/solve_theme.dart';

/// A premium bottom sheet that displays detailed per-stage move statistics.
class SolveStatsSheet extends StatelessWidget {
  final AnalysisController controller;

  const SolveStatsSheet({super.key, required this.controller});

  static Color _stageColor(String displayName, int index) {
    if (displayName == 'Phase 1' || displayName == 'Phase 2') {
      return SolveTheme.primaryIndigo;
    }

    final color = SolveTheme.getStageColor(displayName);
    if (color != SolveTheme.primaryIndigo) return color;

    const fallback = [
      Color(0xFF818CF8), // indigo
      Color(0xFF60A5FA), // blue
      Color(0xFFFACC15), // yellow
      Color(0xFFF59E0B), // amber
      Color(0xFF34D399), // emerald
      Color(0xFFF472B6), // pink
      Color(0xFFA78BFA), // violet
      Color(0xFF38BDF8), // sky
    ];
    return fallback[index % fallback.length];
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = controller.stageBreakdown;
    final totalMoves = controller.solution.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Color(0xFF818CF8), size: 24),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solve Statistics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Per-stage move breakdown',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white38),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Moves',
                  totalMoves.toString(),
                  Icons.speed_rounded,
                  const Color(0xFF818CF8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Stages',
                  breakdown.length.toString(),
                  Icons.layers_rounded,
                  const Color(0xFFFACC15),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Visual Stacked Bar
          const Text(
            'SOLVE COMPOSITION',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 20,
              child: Row(
                children: [
                  for (int i = 0; i < breakdown.length; i++)
                    Expanded(
                      flex: breakdown[i].count,
                      child: Container(
                        color: _stageColor(breakdown[i].name, i),
                        child: i > 0
                            ? Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                      left: BorderSide(
                                          color: Color(0xFF1E1E2E), width: 2)),
                                ),
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Detailed List
          const Text(
            'DETAILED BREAKDOWN',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: breakdown.length,
              separatorBuilder: (_, __) =>
                  Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
              itemBuilder: (context, i) {
                final stage = breakdown[i];
                final color = _stageColor(stage.name, i);
                final percentage = (stage.count / totalMoves * 100).round();

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stage.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Stage ${i + 1}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${stage.count} moves',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              color: color.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
