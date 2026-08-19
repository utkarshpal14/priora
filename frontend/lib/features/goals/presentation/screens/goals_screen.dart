import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/constants/app_colors.dart';
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.black.withValues(alpha: 0.08),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
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
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsState = ref.watch(goalsControllerProvider);
    final goalsNotifier = ref.read(goalsControllerProvider.notifier);
    final filteredGoals = goalsState.filteredGoals;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Long-Term Goals 🎯',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 20),
            tooltip: 'Refresh',
            onPressed: () => goalsNotifier.loadGoals(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreateGoalBottomSheet.show(context),
        backgroundColor: AppColors.primary,
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
        color: AppColors.accent,
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
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('🎯', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 12),
                        Text(
                          'No goals found',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Set your roadmap targets, add checkpoints, and track real progress.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => CreateGoalBottomSheet.show(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Create a Goal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
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
