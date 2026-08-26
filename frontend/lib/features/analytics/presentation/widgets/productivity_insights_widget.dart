import 'package:flutter/material.dart';
import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/analytics/domain/analytics_model.dart';

class ProductivityInsightsWidget extends StatelessWidget {
  final ProductivityInsightsModel insights;
  final TimeOfDayBreakdownModel timeOfDay;

  const ProductivityInsightsWidget({
    super.key,
    required this.insights,
    required this.timeOfDay,
  });

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
              const Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B), size: 22),
              const SizedBox(width: 8),
              Text(
                'Productivity Insights 💡',
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
                child: _buildInsightCard(
                  context: context,
                  title: 'Most Productive Day',
                  value: insights.mostProductiveDay,
                  icon: Icons.calendar_today_rounded,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInsightCard(
                  context: context,
                  title: 'Peak Time Window',
                  value: '${insights.mostProductiveWindow} (${insights.mostProductiveWindowPercentage.toStringAsFixed(0)}%)',
                  icon: Icons.wb_twilight_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Time of Day Distribution',
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildWindowTile(context, 'Morning', '${timeOfDay.morning}', Icons.wb_sunny_rounded, const Color(0xFFF59E0B))),
              const SizedBox(width: 8),
              Expanded(child: _buildWindowTile(context, 'Afternoon', '${timeOfDay.afternoon}', Icons.wb_cloudy_rounded, const Color(0xFF3B82F6))),
              const SizedBox(width: 8),
              Expanded(child: _buildWindowTile(context, 'Evening', '${timeOfDay.evening}', Icons.nights_stay_rounded, const Color(0xFF8B5CF6))),
              const SizedBox(width: 8),
              Expanded(child: _buildWindowTile(context, 'Night', '${timeOfDay.night}', Icons.dark_mode_rounded, const Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
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

  Widget _buildWindowTile(BuildContext context, String label, String count, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(count, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
