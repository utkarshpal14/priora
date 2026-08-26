import 'package:flutter/material.dart';
import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/analytics/domain/analytics_model.dart';

class WeeklyVelocityChartWidget extends StatelessWidget {
  final WeeklyAnalyticsModel weekly;

  const WeeklyVelocityChartWidget({super.key, required this.weekly});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxTasks = weekly.days.fold<int>(1, (max, d) => d.completedCount > max ? d.completedCount : max);

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
                  const Icon(Icons.bar_chart_rounded, color: Color(0xFF3B82F6), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '7-Day Completion Velocity & Trend 📊',
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
          const SizedBox(height: 20),
          if (weekly.days.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No velocity data available',
                  style: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: weekly.days.map((day) => _buildBar(context, day, maxTasks)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBar(BuildContext context, WeeklyDayModel day, int maxTasks) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final heightRatio = (day.completedCount / maxTasks).clamp(0.1, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${day.completionRate.toInt()}%',
          style: TextStyle(
            color: day.completionRate >= 80 ? const Color(0xFF10B981) : (isDark ? Colors.white70 : AppColors.textSecondary),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: 110 * heightRatio,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF3B82F6),
                const Color(0xFF3B82F6).withOpacity(0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '${day.completedCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day.dayLabel,
          style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
