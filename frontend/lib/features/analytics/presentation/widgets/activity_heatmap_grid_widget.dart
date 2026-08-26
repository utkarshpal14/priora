import 'package:flutter/material.dart';
import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/analytics/domain/analytics_model.dart';

class ActivityHeatmapGridWidget extends StatelessWidget {
  final AnalyticsHeatmapModel heatmap;

  const ActivityHeatmapGridWidget({super.key, required this.heatmap});

  Color _getColorForLevel(int level, bool isDark) {
    switch (level) {
      case 1:
        return isDark ? const Color(0xFF0E4429) : const Color(0xFF9BE9A8);
      case 2:
        return isDark ? const Color(0xFF006D32) : const Color(0xFF40C463);
      case 3:
        return isDark ? const Color(0xFF26A641) : const Color(0xFF30A14E);
      case 4:
        return isDark ? const Color(0xFF39D353) : const Color(0xFF216E39);
      default:
        return isDark ? const Color(0xFF161B22) : const Color(0xFFEBEDF0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.grid_on_rounded, color: Color(0xFF26A641), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '30-Day Activity Heatmap 🟩',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No activity data available',
                style: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: heatmap.heatmap.map((day) => _buildHeatmapBlock(context, day, isDark)).toList(),
            ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less ', style: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary, fontSize: 11)),
              _buildLegendBox(0, isDark),
              const SizedBox(width: 4),
              _buildLegendBox(1, isDark),
              const SizedBox(width: 4),
              _buildLegendBox(2, isDark),
              const SizedBox(width: 4),
              _buildLegendBox(3, isDark),
              const SizedBox(width: 4),
              _buildLegendBox(4, isDark),
              const SizedBox(width: 4),
              Text(' More', style: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapBlock(BuildContext context, HeatmapDayModel day, bool isDark) {
    return Tooltip(
      message: '${day.date}: ${day.count} tasks completed',
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: _getColorForLevel(day.level, isDark),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: day.level > 0
                ? const Color(0xFF26A641).withOpacity(0.3)
                : (isDark ? const Color(0xFF30363D) : Colors.black.withValues(alpha: 0.08)),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendBox(int level, bool isDark) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _getColorForLevel(level, isDark),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
