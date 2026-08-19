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
    final isDone = task.isCompleted;
    final isOverdue = task.isOverdue && !isDone;
    final isDueToday = task.isDueToday && !isDone;

    final deadlineColor = isOverdue
        ? const Color(0xFFDC2626)
        : isDueToday
            ? const Color(0xFFD97706)
            : AppColors.textSecondary;

    final deadlineIcon = isOverdue
        ? Icons.error_outline_rounded
        : isDueToday
            ? Icons.today_rounded
            : Icons.access_time_rounded;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDone ? Colors.white.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone
              ? Colors.black.withValues(alpha: 0.04)
              : isOverdue
                  ? const Color(0xFFFCA5A5)
                  : Colors.black.withValues(alpha: 0.08),
          width: isOverdue ? 1.5 : 1,
        ),
        boxShadow: isDone
            ? []
            : [
                BoxShadow(
                  color: isOverdue
                      ? const Color(0xFFDC2626).withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.02),
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
                      color: isDone ? AppColors.accent : Colors.transparent,
                      border: Border.all(
                        color: isDone
                            ? AppColors.accent
                            : isOverdue
                                ? const Color(0xFFDC2626)
                                : AppColors.textSecondary.withValues(alpha: 0.4),
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
                          color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.textSecondary,
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
                                color: AppColors.textSecondary.withValues(alpha: 0.5),
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
                                color: AppColors.textSecondary.withValues(alpha: 0.5),
                              ),
                            ),
                            Text(
                              task.category!.name,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],

                          // Active Reminder Indicator (if scheduled)
                          if (task.hasActiveReminder && !isDone) ...[
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary.withValues(alpha: 0.5),
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
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
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
