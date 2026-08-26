import 'package:flutter/material.dart';
import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/analytics/domain/analytics_model.dart';

class FocusTimeSummaryCardWidget extends StatelessWidget {
  final FocusTimeModel focusTime;

  const FocusTimeSummaryCardWidget({super.key, required this.focusTime});

  String _formatHoursAndMinutes(int minutes) {
    if (minutes <= 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
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
            children: [
              const Icon(Icons.schedule_rounded, color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 8),
              Text(
                'Focus Time Analytics ⏱️',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFocusTile(
                  context: context,
                  title: 'Today',
                  timeText: _formatHoursAndMinutes(focusTime.todayMinutes),
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFocusTile(
                  context: context,
                  title: 'This Week',
                  timeText: _formatHoursAndMinutes(focusTime.weekMinutes),
                  color: const Color(0xFF06B6D4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFocusTile(
                  context: context,
                  title: 'This Month',
                  timeText: _formatHoursAndMinutes(focusTime.monthMinutes),
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusTile({
    required BuildContext context,
    required String title,
    required String timeText,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            timeText,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
