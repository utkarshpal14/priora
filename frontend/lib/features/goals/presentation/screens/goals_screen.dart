import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/shared/widgets/app_empty_view.dart';
import 'package:frontend/shared/widgets/app_error_view.dart';
import 'package:frontend/features/goals/domain/goal_model.dart';
import 'package:frontend/features/goals/presentation/controllers/goals_controller.dart';
import 'package:frontend/features/goals/presentation/widgets/create_goal_bottom_sheet.dart';
import 'package:frontend/features/goals/presentation/widgets/goal_card.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = isDark ? theme.colorScheme.secondary : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final goalsState = ref.watch(goalsControllerProvider);
    final goalsNotifier = ref.read(goalsControllerProvider.notifier);
    final filteredGoals = goalsState.filteredGoals;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Long-Term Goals 🎯',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary, size: 20),
            tooltip: 'Refresh',
            onPressed: () => goalsNotifier.loadGoals(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreateGoalBottomSheet.show(context),
        backgroundColor: isDark ? theme.colorScheme.secondary : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          'New Goal',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => goalsNotifier.loadGoals(),
        color: theme.colorScheme.secondary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Metrics Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${goalsState.inProgressCount}',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'In Progress',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                    Column(
                      children: [
                        Text(
                          '${goalsState.completedCount}',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF34D399),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Achieved',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                    Column(
                      children: [
                        Text(
                          '${goalsState.totalCount}',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total Goals',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip(
                      context: context,
                      label: 'All (${goalsState.totalCount})',
                      isSelected: goalsState.selectedStatusFilter == null,
                      onTap: () => goalsNotifier.selectFilter(null),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context: context,
                      label: 'In Progress (${goalsState.inProgressCount})',
                      isSelected: goalsState.selectedStatusFilter == GoalStatus.inProgress,
                      onTap: () => goalsNotifier.selectFilter(GoalStatus.inProgress),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context: context,
                      label: 'Completed (${goalsState.completedCount})',
                      isSelected: goalsState.selectedStatusFilter == GoalStatus.completed,
                      onTap: () => goalsNotifier.selectFilter(GoalStatus.completed),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context: context,
                      label: 'Paused',
                      isSelected: goalsState.selectedStatusFilter == GoalStatus.paused,
                      onTap: () => goalsNotifier.selectFilter(GoalStatus.paused),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Goals List or Empty State
              if (goalsState.isLoading && goalsState.goals.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                )
              else if (filteredGoals.isEmpty)
                AppEmptyView(
                  icon: Icons.flag_rounded,
                  title: 'No goals created yet',
                  message: 'Start with a learning objective, placement milestone, or personal habit.',
                  actionLabel: 'New Goal',
                  onActionPressed: () => CreateGoalBottomSheet.show(context),
                )
              else
                ...filteredGoals.map((g) => GoalCard(
                      goal: g,
                      onTap: () => context.push('/goals/${g.id}'),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
