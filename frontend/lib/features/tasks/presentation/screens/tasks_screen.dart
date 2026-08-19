import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => tasksNotifier.setSearchQuery(val),
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
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

  Widget _buildEmptyState(BuildContext context, TaskTabFilter tabFilter) {
    String message = 'No tasks yet';
    String subMessage = 'Create your first task to get started.';

    if (tabFilter == TaskTabFilter.completed) {
      message = 'No completed tasks';
      subMessage = 'Tasks you finish will show up here.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 32,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            if (tabFilter != TaskTabFilter.completed)
              ElevatedButton.icon(
                onPressed: () => CreateTaskBottomSheet.show(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Create Task',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
