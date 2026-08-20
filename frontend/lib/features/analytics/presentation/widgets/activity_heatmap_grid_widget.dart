import 'package:flutter/material.dart';
import 'package:frontend/features/analytics/domain/analytics_model.dart';

class ActivityHeatmapGridWidget extends StatelessWidget {
  final AnalyticsHeatmapModel heatmap;

  const ActivityHeatmapGridWidget({super.key, required this.heatmap});

  Color _getColorForLevel(int level) {
    switch (level) {
      case 1:
        return const Color(0xFF0E4429);
      case 2:
        return const Color(0xFF006D32);
      case 3:
        return const Color(0xFF26A641);
      case 4:
        return const Color(0xFF39D353);
      default:
        return const Color(0xFF161B22);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.grid_on_rounded, color: Color(0xFF26A641), size: 22),
                  SizedBox(width: 8),
                  Text(
                    '30-Day Activity Heatmap 🟩',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (heatmap.heatmap.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No activity data available', style: TextStyle(color: Colors.white54)),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: heatmap.heatmap.map((day) => _buildHeatmapBlock(context, day)).toList(),
            ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Less ', style: TextStyle(color: Colors.white54, fontSize: 11)),
              _buildLegendBox(0),
              const SizedBox(width: 4),
              _buildLegendBox(1),
              const SizedBox(width: 4),
              _buildLegendBox(2),
              const SizedBox(width: 4),
              _buildLegendBox(3),
              const SizedBox(width: 4),
              _buildLegendBox(4),
              const SizedBox(width: 4),
              const Text(' More', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapBlock(BuildContext context, HeatmapDayModel day) {
    return Tooltip(
      message: '${day.date}: ${day.count} tasks completed',
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: _getColorForLevel(day.level),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: day.level > 0 ? const Color(0xFF26A641).withOpacity(0.3) : const Color(0xFF30363D),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendBox(int level) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _getColorForLevel(level),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
