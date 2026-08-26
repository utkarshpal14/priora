import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:frontend/features/planner/presentation/controllers/planner_controller.dart';
import 'package:frontend/features/planner/presentation/widgets/calendar_strip.dart';
import 'package:frontend/features/planner/presentation/widgets/hourly_timeline_section.dart';
import 'package:frontend/features/planner/presentation/widgets/planner_progress_summary.dart';
import 'package:frontend/features/planner/presentation/widgets/smart_focus_section.dart';
import 'package:frontend/features/planner/presentation/widgets/weekly_preview_section.dart';
import 'package:frontend/features/review/presentation/widgets/evening_review_banner.dart';
import 'package:frontend/features/tasks/presentation/widgets/create_task_bottom_sheet.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final plannerState = ref.watch(plannerControllerProvider);
    final plannerNotifier = ref.read(plannerControllerProvider.notifier);
    final authState = ref.watch(authControllerProvider);
    final userName = authState.user?.fullName?.split(' ').first ?? 'there';

    final dailyPlan = plannerState.dailyPlan;
    final weeklyPlan = plannerState.weeklyPlan;
    final overdueTasks = dailyPlan?.overdueTasks ?? [];
    final focusTasks = dailyPlan?.focusTasks ?? [];
    final timeBlocks = dailyPlan?.timeBlocks ?? [];
    final unscheduledTasks = dailyPlan?.unscheduledTasks ?? [];
    final summary = dailyPlan?.summary;

    // Construct map of date -> task count from weekly plan for calendar strip dots
    final taskCountMap = <String, int>{};
    if (weeklyPlan != null) {
      for (final day in weeklyPlan.days) {
        taskCountMap[day.date] = day.taskCount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plannerState.isViewingToday
                  ? "Today's Plan 🎯"
                  : DateFormat('EEEE, MMM d').format(plannerState.selectedDate),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              'Welcome, $userName 👋',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white : AppColors.textPrimary),
            tooltip: 'Refresh Plan',
            onPressed: () => plannerNotifier.loadData(),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white : AppColors.textPrimary),
            tooltip: 'Settings & Diagnostics',
            onPressed: () => context.go('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            tooltip: 'Log Out',
            onPressed: () => _showLogoutDialog(context, ref),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreateTaskBottomSheet.show(context),
        backgroundColor: isDark ? theme.colorScheme.secondary : AppColors.primary,
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
        color: theme.colorScheme.secondary,
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
                // 2. Overdue Alert (if overdue tasks exist)
                if (overdueTasks.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5)),
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
                              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 6),

                // 3. Hourly Timeline Schedule with Time Blocks & Unscheduled Tasks
                HourlyTimelineSection(
                  timeBlocks: timeBlocks,
                  unscheduledTasks: unscheduledTasks,
                  isViewingToday: plannerState.isViewingToday,
                  selectedDate: plannerState.selectedDate,
                  onDeleteSession: (sessionId) => plannerNotifier.deleteSession(sessionId),
                  onToggleTaskComplete: (task) => plannerNotifier.toggleTaskCompletion(task),
                  onStartTask: (task) => plannerNotifier.startTask(task),
                ),

                const SizedBox(height: 10),

                // 4. Top 3 Smart Focus Priorities
                SmartFocusSection(
                  focusTasks: focusTasks,
                  onToggleComplete: (task) => plannerNotifier.toggleTaskCompletion(task),
                  onStartTask: (task) => plannerNotifier.startTask(task),
                ),

                const SizedBox(height: 14),

                // 5. Daily Progress Summary & Evening Review
                if (summary != null)
                  PlannerProgressSummary(
                    summary: summary,
                    isViewingToday: plannerState.isViewingToday,
                  ),

                if (plannerState.isViewingToday)
                  EveningReviewBanner(
                    incompleteCount: summary?.pending ?? 0,
                  ),

                // 6. Weekly Overview
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

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log Out of Priora?',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to sign out? Your tasks and preferences will remain securely saved.',
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
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
