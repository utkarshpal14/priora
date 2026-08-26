import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/category_model.dart';
import '../../domain/task_model.dart';
import '../../domain/tasks_state.dart';

class TaskFilterChips extends StatelessWidget {
  final TaskTabFilter currentTab;
  final TaskMetricsModel metrics;
  final ValueChanged<TaskTabFilter> onTabChanged;
  final TaskPriority? currentPriority;
  final ValueChanged<TaskPriority?> onPriorityChanged;
  final List<CategoryModel> categories;
  final String? currentCategoryId;
  final ValueChanged<String?> onCategoryChanged;

  const TaskFilterChips({
    super.key,
    required this.currentTab,
    required this.metrics,
    required this.onTabChanged,
    this.currentPriority,
    required this.onPriorityChanged,
    this.categories = const [],
    this.currentCategoryId,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented Status Filter Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTabButton(
                  context: context,
                  title: 'Pending',
                  count: metrics.pending,
                  isSelected: currentTab == TaskTabFilter.pending,
                  onTap: () => onTabChanged(TaskTabFilter.pending),
                ),
                _buildTabButton(
                  context: context,
                  title: 'Overdue',
                  count: metrics.overdue,
                  isSelected: currentTab == TaskTabFilter.overdue,
                  badgeColor: metrics.overdue > 0 ? const Color(0xFFDC2626) : null,
                  badgeTextColor: metrics.overdue > 0 ? Colors.white : null,
                  onTap: () => onTabChanged(TaskTabFilter.overdue),
                ),
                _buildTabButton(
                  context: context,
                  title: 'Completed',
                  count: metrics.completed,
                  isSelected: currentTab == TaskTabFilter.completed,
                  onTap: () => onTabChanged(TaskTabFilter.completed),
                ),
                _buildTabButton(
                  context: context,
                  title: 'All',
                  count: metrics.total,
                  isSelected: currentTab == TaskTabFilter.all,
                  onTap: () => onTabChanged(TaskTabFilter.all),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Priority Filter Pills + Category Dropdown
          Row(
            children: [
              // Scalable Category Dropdown Selector
              if (categories.isNotEmpty) ...[
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: currentCategoryId != null
                        ? theme.colorScheme.secondary.withValues(alpha: 0.15)
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: currentCategoryId != null
                          ? theme.colorScheme.secondary
                          : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
                      width: currentCategoryId != null ? 1.5 : 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: currentCategoryId,
                      isDense: true,
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: currentCategoryId != null
                            ? theme.colorScheme.secondary
                            : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...categories.map((c) {
                          return DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(c.name),
                          );
                        }),
                      ],
                      onChanged: onCategoryChanged,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Priority Filter Pills (Scrollable horizontal row)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPriorityChip(
                        context: context,
                        label: 'All Priorities',
                        isSelected: currentPriority == null,
                        onTap: () => onPriorityChanged(null),
                      ),
                      const SizedBox(width: 6),
                      ...TaskPriority.values.map((p) {
                        final isSelected = currentPriority == p;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _buildPriorityChip(
                            context: context,
                            label: p.label,
                            color: p.color,
                            isSelected: isSelected,
                            onTap: () => onPriorityChanged(isSelected ? null : p),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required BuildContext context,
    required String title,
    required int count,
    required bool isSelected,
    Color? badgeColor,
    Color? badgeTextColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveBadgeColor = badgeColor ??
        (isSelected
            ? theme.colorScheme.secondary.withValues(alpha: 0.18)
            : (isDark ? const Color(0xFF0F172A) : Colors.black.withValues(alpha: 0.05)));
    final effectiveTextColor = badgeTextColor ??
        (isSelected ? theme.colorScheme.secondary : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary));

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : [],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? (isDark ? Colors.white : AppColors.textPrimary) : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: effectiveBadgeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: effectiveTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip({
    required BuildContext context,
    required String label,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = color ?? (isDark ? Colors.white : AppColors.textPrimary);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeColor : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
