import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/tasks/domain/task_model.dart';
import 'package:frontend/features/tasks/presentation/widgets/edit_task_bottom_sheet.dart';

class SmartFocusSection extends StatelessWidget {
  final List<TaskModel> focusTasks;
  final ValueChanged<TaskModel> onToggleComplete;
  final ValueChanged<TaskModel> onStartTask;

  const SmartFocusSection({
    super.key,
    required this.focusTasks,
    required this.onToggleComplete,
    required this.onStartTask,
  });

  @override
  Widget build(BuildContext context) {
    if (focusTasks.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.stars_rounded, size: 18, color: Color(0xFFD97706)),
              const SizedBox(width: 6),
              Text(
                "Top Focus",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${focusTasks.length} PRIORITIES',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        // List of Focus Task Cards
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: focusTasks.length,
          itemBuilder: (context, index) {
            final task = focusTasks[index];
            final isInProgress = task.status == TaskStatus.inProgress;
            final isDone = task.isCompleted;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isInProgress
                      ? theme.colorScheme.secondary.withValues(alpha: 0.5)
                      : (task.priority == TaskPriority.critical
                          ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5))
                          : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06))),
                  width: isInProgress || task.priority == TaskPriority.critical ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => EditTaskBottomSheet.show(context, task),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Focus Ranking Number + Title + Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFEF3C7),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFD97706), width: 1),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Title & Description
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDone
                                          ? (isDark ? const Color(0xFF64748B) : AppColors.textSecondary)
                                          : (isDark ? Colors.white : AppColors.textPrimary),
                                      decoration: isDone ? TextDecoration.lineThrough : null,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (task.description != null && task.description!.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      task.description!,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Badges & Action Buttons Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Badges: Priority • Duration • Category
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: task.priority.backgroundColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    task.priority.label.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: task.priority.color,
                                    ),
                                  ),
                                ),
                                if (task.formattedDuration != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.timer_outlined, size: 11, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                                        const SizedBox(width: 3),
                                        Text(
                                          task.formattedDuration!,
                                          style: GoogleFonts.inter(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (task.category != null)
                                  Text(
                                    task.category!.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),

                            // Action Buttons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isDone && !isInProgress)
                                  GestureDetector(
                                    onTap: () => onStartTask(task),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? theme.colorScheme.secondary.withValues(alpha: 0.15)
                                            : AppColors.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.play_arrow_rounded,
                                            size: 14,
                                            color: isDark ? theme.colorScheme.secondary : AppColors.primary,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            'Start',
                                            style: GoogleFonts.inter(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? theme.colorScheme.secondary : AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => onToggleComplete(task),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))
                                          : theme.colorScheme.secondary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isDone ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                                          size: 14,
                                          color: isDone
                                              ? (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary)
                                              : theme.colorScheme.secondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isDone ? 'Reopen' : 'Done',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDone
                                              ? (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary)
                                              : theme.colorScheme.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
