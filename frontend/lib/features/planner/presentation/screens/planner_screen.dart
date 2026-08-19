import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:frontend/features/planner/presentation/controllers/planner_controller.dart';
import 'package:frontend/features/planner/presentation/widgets/calendar_strip.dart';
import 'package:frontend/features/planner/presentation/widgets/planner_progress_summary.dart';
import 'package:frontend/features/planner/presentation/widgets/smart_focus_section.dart';
import 'package:frontend/features/planner/presentation/widgets/timeline_schedule_section.dart';
import 'package:frontend/features/planner/presentation/widgets/weekly_preview_section.dart';
import 'package:frontend/features/tasks/presentation/widgets/create_task_bottom_sheet.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannerState = ref.watch(plannerControllerProvider);
    final plannerNotifier = ref.read(plannerControllerProvider.notifier);
    final authState = ref.watch(authControllerProvider);
    final userName = authState.user?.fullName?.split(' ').first ?? 'there';

    final dailyPlan = plannerState.dailyPlan;
    final weeklyPlan = plannerState.weeklyPlan;
    final overdueTasks = dailyPlan?.overdueTasks ?? [];
    final focusTasks = dailyPlan?.focusTasks ?? [];
    final timelineBuckets = dailyPlan?.timeline ?? [];
    final summary = dailyPlan?.summary;

    // Construct map of date -> task count from weekly plan for calendar strip dots
    final taskCountMap = <String, int>{};
    if (weeklyPlan != null) {
      for (final day in weeklyPlan.days) {
        taskCountMap[day.date] = day.dueCount;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Planner 📅',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              plannerState.isViewingToday
                  ? "Plan your day, $userName"
                  : DateFormat('MMMM d, yyyy').format(plannerState.selectedDate),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 20),
            tooltip: 'Refresh Plan',
            onPressed: () => plannerNotifier.loadData(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreateTaskBottomSheet.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_task_rounded, size: 20),
        label: Text(
          'Add to Plan',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => plannerNotifier.loadData(),
        color: AppColors.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Calendar Strip
              CalendarStrip(
                selectedDate: plannerState.selectedDate,
                onDateSelected: (date) => plannerNotifier.selectDate(date),
                taskCountByDate: taskCountMap,
              ),

              if (plannerState.isLoading && dailyPlan == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              else ...[
                // 2. Progress Summary
                if (summary != null)
                  PlannerProgressSummary(
                    summary: summary,
                    isViewingToday: plannerState.isViewingToday,
                  ),

                // 3. Overdue Alert (if overdue tasks exist)
                if (overdueTasks.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFDC2626)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${overdueTasks.length} overdue task${overdueTasks.length > 1 ? 's' : ''} require attention!',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 6),

                // 4. Top 3 Smart Focus
                SmartFocusSection(
                  focusTasks: focusTasks,
                  onToggleComplete: (task) => plannerNotifier.toggleTaskCompletion(task),
                  onStartTask: (task) => plannerNotifier.startTask(task),
                ),

                const SizedBox(height: 10),

                // 5. Timeline Schedule
                TimelineScheduleSection(
                  timelineBuckets: timelineBuckets,
                  onToggleComplete: (task) => plannerNotifier.toggleTaskCompletion(task),
                  onMoveToToday: (taskId) => plannerNotifier.moveToToday(taskId),
                  isViewingToday: plannerState.isViewingToday,
                ),

                const SizedBox(height: 14),

                // 6. Weekly Preview
                if (weeklyPlan != null)
                  WeeklyPreviewSection(
                    weeklyPlan: weeklyPlan,
                    onSelectDate: (date) => plannerNotifier.selectDate(date),
                  ),

                const SizedBox(height: 90), // Bottom padding for FAB and navbar
              ],
            ],
          ),
        ),
      ),
    );
  }
}
