import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/goals/domain/goal_model.dart';
import 'package:frontend/features/goals/presentation/controllers/goals_controller.dart';
import 'package:frontend/features/goals/presentation/widgets/add_milestone_bottom_sheet.dart';
import 'package:frontend/features/goals/presentation/widgets/create_goal_bottom_sheet.dart';
import 'package:frontend/features/tasks/presentation/controllers/tasks_controller.dart';
import 'package:frontend/features/tasks/presentation/widgets/create_task_bottom_sheet.dart';
import 'package:frontend/features/tasks/presentation/widgets/task_card.dart';

class GoalDetailScreen extends ConsumerStatefulWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(goalsControllerProvider.notifier).loadGoalDetail(widget.goalId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmDeleteGoal(GoalModel goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Goal?',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete "${goal.title}"? Linked tasks will remain saved.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success =
                  await ref.read(goalsControllerProvider.notifier).deleteGoal(goal.id);
              if (success && mounted) {
                context.pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsState = ref.watch(goalsControllerProvider);
    final goalsNotifier = ref.read(goalsControllerProvider.notifier);
    final goal = goalsState.selectedGoal;

    if (goalsState.isLoading && goal == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (goal == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Goal not found', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: () => context.pop(), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    final progress = (goal.progressPercentage / 100.0).clamp(0.0, 1.0);
    final daysRemaining = goal.daysRemaining;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
            tooltip: 'Edit Goal',
            onPressed: () => CreateGoalBottomSheet.show(context, goalToEdit: goal),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
            tooltip: 'Delete Goal',
            onPressed: () => _confirmDeleteGoal(goal),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                              color: goal.displayColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            goal.category?.name ?? 'General',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: goal.status.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          goal.status.label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: goal.status.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    goal.title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  if (goal.description != null && goal.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      goal.description!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Progress Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${goal.progressPercentage.toInt()}% Complete',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 9,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(goal.displayColor),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Target Date Row
                  if (goal.formattedTargetDate != null)
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Target: ${goal.formattedTargetDate!}',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (daysRemaining != null) ...[
                          Text(' • ', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                          Text(
                            daysRemaining < 0
                                ? 'Overdue'
                                : daysRemaining == 0
                                    ? 'Due Today'
                                    : '$daysRemaining days remaining',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: daysRemaining < 0 ? const Color(0xFFDC2626) : AppColors.accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500),
                tabs: [
                  Tab(text: 'Milestones (${goal.milestones.length})'),
                  Tab(text: 'Tasks (${goal.tasks.length})'),
                  const Tab(text: 'Activity ⚡'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: Milestones
            SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Checkpoints & Phases',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => AddMilestoneBottomSheet.show(
                          context,
                          goalId: goal.id,
                          nextOrderIndex: goal.milestones.length + 1,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Milestone', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  if (goal.milestones.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                      ),
                      child: Center(
                        child: Text(
                          'No milestones added yet. Break down this goal into 2–4 checkpoints.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...goal.milestones.map((m) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: m.isCompleted
                                  ? AppColors.accent.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => goalsNotifier.toggleMilestone(goal.id, m.id),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: BoxDecoration(
                                    color: m.isCompleted ? AppColors.accent : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: m.isCompleted
                                          ? AppColors.accent
                                          : Colors.black.withValues(alpha: 0.25),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: m.isCompleted
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.title,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: m.isCompleted
                                            ? AppColors.textSecondary
                                            : AppColors.textPrimary,
                                        decoration:
                                            m.isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    if (m.description != null && m.description!.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        m.description!,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    if (m.formattedTargetDate != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.flag_outlined, size: 11, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            m.formattedTargetDate!,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                                onPressed: () => goalsNotifier.deleteMilestone(goal.id, m.id),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),

            // TAB 2: Linked Tasks
            SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Associated Tasks',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => CreateTaskBottomSheet.show(context),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Task', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  if (goal.tasks.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                      ),
                      child: Center(
                        child: Text(
                          'No daily tasks linked to this goal yet. Link tasks from the Tasks tab or add one here.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...goal.tasks.map((t) => TaskCard(
                          task: t,
                          onToggleComplete: (task) async {
                            await ref
                                .read(tasksControllerProvider.notifier)
                                .toggleTaskCompletion(task);
                            await goalsNotifier.loadGoalDetail(goal.id);
                            await goalsNotifier.loadGoals();
                          },
                          onTap: () {},
                        )),
                ],
              ),
            ),

            // TAB 3: Recent Activity
            SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Completion Timeline',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (goal.recentActivity.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                      ),
                      child: Center(
                        child: Text(
                          'No completed activity recorded yet. Check off milestones or tasks to see your timeline.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...goal.recentActivity.map((act) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: act.type == 'MILESTONE'
                                      ? const Color(0xFFFEF3C7)
                                      : const Color(0xFFDCFCE7),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  act.type == 'MILESTONE' ? '🚩' : '✓',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Completed ${act.type == 'MILESTONE' ? 'milestone' : 'task'}: "${act.title}"',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (act.description != null && act.description!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        act.description!,
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                act.timeAgo,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
