import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_empty_view.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/tasks_state.dart';
import '../controllers/tasks_controller.dart';
import '../widgets/create_task_bottom_sheet.dart';
import '../widgets/edit_task_bottom_sheet.dart';
import '../widgets/task_card.dart';
import '../widgets/task_filter_chips.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksControllerProvider);
    final tasksNotifier = ref.read(tasksControllerProvider.notifier);
    final authState = ref.watch(authControllerProvider);
    final filteredTasks = tasksState.filteredTasks;

    final userName = authState.user?.fullName?.split(' ').first ?? 'there';

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
              'Hello, $userName 👋',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${tasksState.metrics.pending} pending • ${tasksState.metrics.completed} completed',
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
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary, size: 22),
            tooltip: 'Settings & Preferences',
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 20),
            tooltip: 'Log out',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreateTaskBottomSheet.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          'New Task',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => tasksNotifier.loadData(),
        color: AppColors.accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => tasksNotifier.setSearchQuery(val),
                  style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              tasksNotifier.setSearchQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter Chips Bar (Status tabs + Category Dropdown + Priority pills)
            TaskFilterChips(
              currentTab: tasksState.tabFilter,
              metrics: tasksState.metrics,
              onTabChanged: (tab) => tasksNotifier.setTabFilter(tab),
              currentPriority: tasksState.priorityFilter,
              onPriorityChanged: (p) => tasksNotifier.setPriorityFilter(p),
              categories: tasksState.categories,
              currentCategoryId: tasksState.categoryFilterId,
              onCategoryChanged: (catId) => tasksNotifier.setCategoryFilter(catId),
            ),
            const SizedBox(height: 8),

            // Smart Urgency Banner (Overdue > Due Today > Hidden)
            _buildSmartBanner(context, tasksState, tasksNotifier),

            // Error Banner (if any)
            if (tasksState.errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tasksState.errorMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFDC2626),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 14, color: Color(0xFFDC2626)),
                      onPressed: () => tasksNotifier.clearError(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            // Tasks List / Empty State / Loading Indicator
            Expanded(
              child: tasksState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                      ),
                    )
                  : filteredTasks.isEmpty
                      ? _buildEmptyState(context, tasksState.tabFilter)
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 80),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            return TaskCard(
                              key: ValueKey(task.id),
                              task: task,
                              onTap: () => EditTaskBottomSheet.show(context, task),
                              onToggleComplete: (t) => tasksNotifier.toggleTaskCompletion(t),
                              onDelete: (t) => tasksNotifier.deleteTask(t.id),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartBanner(BuildContext context, TasksState state, TasksController notifier) {
    if (state.metrics.overdue > 0) {
      final count = state.metrics.overdue;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFDC2626)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count ${count == 1 ? "overdue task needs" : "overdue tasks need"} attention',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF991B1B),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => notifier.setTabFilter(TaskTabFilter.overdue),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'View Tasks',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (state.metrics.dueToday > 0) {
      final count = state.metrics.dueToday;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 17, color: Color(0xFFD97706)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count ${count == 1 ? "task" : "tasks"} due today',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF92400E),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => notifier.setTabFilter(TaskTabFilter.pending),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Review Schedule',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(BuildContext context, TaskTabFilter tabFilter) {
    if (tabFilter == TaskTabFilter.today) {
      return AppEmptyView(
        icon: Icons.today_rounded,
        title: 'No tasks due today',
        message: 'Stay ahead of your schedule by creating a task with today\'s deadline.',
        actionLabel: 'Create Task',
        onActionPressed: () => CreateTaskBottomSheet.show(context),
      );
    } else if (tabFilter == TaskTabFilter.completed) {
      return const AppEmptyView(
        icon: Icons.check_circle_outline_rounded,
        title: 'No completed tasks',
        message: 'Tasks you finish will show up here.',
      );
    } else if (tabFilter == TaskTabFilter.overdue) {
      return const AppEmptyView(
        icon: Icons.celebration_rounded,
        title: '🎉 No overdue tasks',
        message: "You're all caught up! Great job staying on top of your priorities.",
      );
    }

    return AppEmptyView(
      icon: Icons.task_alt_rounded,
      title: 'No tasks yet',
      message: 'Organize your day, track deadlines, and accomplish your goals.',
      actionLabel: 'Create Task',
      onActionPressed: () => CreateTaskBottomSheet.show(context),
    );
  }
}
