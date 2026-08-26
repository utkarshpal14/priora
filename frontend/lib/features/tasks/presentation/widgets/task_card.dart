import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final ValueChanged<TaskModel> onToggleComplete;
  final ValueChanged<TaskModel>? onDelete;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleComplete,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDone = task.isCompleted;
    final isOverdue = task.isOverdue && !isDone;
    final isDueToday = task.isDueToday && !isDone;

    final deadlineColor = isOverdue
        ? const Color(0xFFDC2626)
        : isDueToday
            ? const Color(0xFFD97706)
            : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary);

    final deadlineIcon = isOverdue
        ? Icons.error_outline_rounded
        : isDueToday
            ? Icons.today_rounded
            : Icons.access_time_rounded;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDone ? theme.colorScheme.surface.withValues(alpha: 0.6) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone
              ? (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04))
              : isOverdue
                  ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5))
                  : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
          width: isOverdue ? 1.5 : 1,
        ),
        boxShadow: isDone
            ? []
            : [
                BoxShadow(
                  color: isOverdue
                      ? const Color(0xFFDC2626).withValues(alpha: 0.04)
                      : (isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02)),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Minimalist Circular Checkbox
                GestureDetector(
                  onTap: () => onToggleComplete(task),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? theme.colorScheme.secondary : Colors.transparent,
                      border: Border.all(
                        color: isDone
                            ? theme.colorScheme.secondary
                            : isOverdue
                                ? const Color(0xFFDC2626)
                                : (isDark ? const Color(0xFF64748B) : AppColors.textSecondary.withValues(alpha: 0.4)),
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),

                // Task Content (Title + Subline)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task Title
                      Text(
                        task.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDone
                              ? (isDark ? const Color(0xFF64748B) : AppColors.textSecondary)
                              : (isDark ? Colors.white : AppColors.textPrimary),
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          decorationColor: isDark ? const Color(0xFF64748B) : AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Clean Subline: Deadline • Priority • Category
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // Deadline
                          if (task.deadline != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  deadlineIcon,
                                  size: 13,
                                  color: deadlineColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  task.formattedDeadline,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: deadlineColor,
                                    fontWeight: isOverdue || isDueToday
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                          if (task.deadline != null)
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: 10,
                                color: (isDark ? const Color(0xFF64748B) : AppColors.textSecondary).withValues(alpha: 0.5),
                              ),
                            ),

                          // Priority Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: task.priority.backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task.priority.label.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: task.priority.color,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),

                          // Category Chip (if present)
                          if (task.category != null) ...[
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: 10,
                                color: (isDark ? const Color(0xFF64748B) : AppColors.textSecondary).withValues(alpha: 0.5),
                              ),
                            ),
                            Text(
                              task.category!.name,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],

                          // Recurring Indicator Chip (ENH-005)
                          if (task.isRecurring) ...[
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: 10,
                                color: (isDark ? const Color(0xFF64748B) : AppColors.textSecondary).withValues(alpha: 0.5),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isDark ? theme.colorScheme.secondary : AppColors.primary).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.repeat_rounded,
                                    size: 12,
                                    color: isDark ? theme.colorScheme.secondary : AppColors.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    task.repeatLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? theme.colorScheme.secondary : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Scheduled Focus Time Range (if scheduled)
                          if (task.formattedTimeRange != null) ...[
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: 10,
                                color: (isDark ? const Color(0xFF64748B) : AppColors.textSecondary).withValues(alpha: 0.5),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isDark ? theme.colorScheme.secondary.withValues(alpha: 0.15) : const Color(0xFFE0E7FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 11.5,
                                    color: isDark ? theme.colorScheme.secondary : AppColors.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    task.formattedTimeRange!,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: isDark ? theme.colorScheme.secondary : AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Active Reminder Indicator (if scheduled)
                          if (task.hasActiveReminder && !isDone) ...[
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: 10,
                                color: (isDark ? const Color(0xFF64748B) : AppColors.textSecondary).withValues(alpha: 0.5),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.notifications_active_rounded,
                                  size: 12.5,
                                  color: Color(0xFFD97706),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  task.reminders.firstWhere((r) => r.isScheduled).formattedRemindAt,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: const Color(0xFFD97706),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Attachment Counter Badge (if task has attachments)
                          if (task.attachmentCount > 0) ...[
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: 10,
                                color: (isDark ? const Color(0xFF64748B) : AppColors.textSecondary).withValues(alpha: 0.5),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.attach_file_rounded,
                                  size: 12.5,
                                  color: Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${task.attachmentCount}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: const Color(0xFF6366F1),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Delete Button Action
                if (onDelete != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: isDark ? const Color(0xFF64748B) : AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
                    onPressed: () => onDelete!(task),
                    tooltip: 'Delete task',
                    splashRadius: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
