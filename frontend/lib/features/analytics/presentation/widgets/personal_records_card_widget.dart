import 'package:flutter/material.dart';
import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/analytics/domain/analytics_model.dart';

class PersonalRecordsCardWidget extends StatelessWidget {
  final PersonalRecordsModel records;

  const PersonalRecordsCardWidget({super.key, required this.records});

  String _formatMinutes(int minutes) {
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
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 22),
              const SizedBox(width: 8),
              Text(
                'Personal Best Records 🏆',
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
                child: _buildRecordItem(
                  context: context,
                  icon: Icons.task_alt_rounded,
                  title: 'Best Day',
                  value: '${records.bestDayTasks} tasks',
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRecordItem(
                  context: context,
                  icon: Icons.timer_rounded,
                  title: 'Peak Focus',
                  value: _formatMinutes(records.bestDayFocusMinutes),
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRecordItem(
                  context: context,
                  icon: Icons.local_fire_department_rounded,
                  title: 'Max Streak',
                  value: '${records.longestStreak} days',
                  color: const Color(0xFFF97316),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
