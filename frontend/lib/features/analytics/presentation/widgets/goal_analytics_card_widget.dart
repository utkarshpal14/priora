import 'package:flutter/material.dart';
import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/analytics/domain/analytics_model.dart';

class GoalAnalyticsCardWidget extends StatelessWidget {
  final GoalAnalyticsModel goals;

  const GoalAnalyticsCardWidget({super.key, required this.goals});

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
              const Icon(Icons.flag_rounded, color: Color(0xFF6366F1), size: 22),
              const SizedBox(width: 8),
              Text(
                'Goals & Milestones Progression 🎯',
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
                child: _buildStatBadge(
                  context: context,
                  label: 'Active Goals',
                  value: '${goals.activeGoals}',
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBadge(
                  context: context,
                  label: 'Completed',
                  value: '${goals.completedGoals}',
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBadge(
                  context: context,
                  label: 'Milestones Done',
                  value: '${goals.completedMilestones} / ${goals.totalMilestones}',
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(
            context: context,
            label: 'Goals Completion',
            percentage: goals.goalCompletionRate,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 10),
          _buildProgressBar(
            context: context,
            label: 'Milestones Completion',
            percentage: goals.milestoneCompletionRate,
            color: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required BuildContext context,
    required String label,
    required double percentage,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary, fontSize: 12),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percentage / 100.0).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
