import 'package:flutter/material.dart';
import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/analytics/domain/analytics_model.dart';

class CategoryBreakdownWidget extends StatelessWidget {
  final AnalyticsBreakdownModel breakdown;

  const CategoryBreakdownWidget({super.key, required this.breakdown});

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
              const Icon(Icons.pie_chart_rounded, color: Color(0xFF8B5CF6), size: 22),
              const SizedBox(width: 8),
              Text(
                'Category Distribution 🎨',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (breakdown.categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No categories data available',
                style: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary),
              ),
            )
          else
            Column(
              children: breakdown.categories.map((cat) => _buildCategoryRow(context, cat)).toList(),
            ),
          const SizedBox(height: 20),
          Text(
            'Tasks Completed by Priority',
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPriorityChip('Critical', breakdown.priorities.critical, const Color(0xFFEF4444)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPriorityChip('High', breakdown.priorities.high, const Color(0xFFF97316)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPriorityChip('Medium', breakdown.priorities.medium, const Color(0xFFEAB308)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPriorityChip('Low', breakdown.priorities.low, const Color(0xFF10B981)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(BuildContext context, CategoryBreakdownItemModel cat) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: cat.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cat.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                '${cat.count} tasks (${cat.percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (cat.percentage / 100.0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(cat.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
