import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/planner/domain/planner_model.dart';
import 'package:frontend/features/tasks/domain/task_model.dart';
import 'package:frontend/features/tasks/presentation/widgets/edit_task_bottom_sheet.dart';

class TimelineScheduleSection extends StatelessWidget {
  final List<TimelineBucketModel> timelineBuckets;
  final ValueChanged<TaskModel> onToggleComplete;
  final ValueChanged<String> onMoveToToday;
  final bool isViewingToday;

  const TimelineScheduleSection({
    super.key,
    required this.timelineBuckets,
    required this.onToggleComplete,
    required this.onMoveToToday,
    required this.isViewingToday,
  });

  IconData _getBucketIcon(String name) {
    switch (name.toLowerCase()) {
      case 'morning':
        return Icons.wb_sunny_outlined;
      case 'afternoon':
        return Icons.wb_sunny_rounded;
      case 'evening':
        return Icons.nights_stay_outlined;
      default:
        return Icons.all_inclusive_rounded;
    }
  }

  Color _getBucketColor(String name) {
    switch (name.toLowerCase()) {
      case 'morning':
        return const Color(0xFFD97706);
      case 'afternoon':
        return const Color(0xFFEA580C);
      case 'evening':
        return const Color(0xFF6366F1);
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                "Timeline & Schedule",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Timeline Bucket Cards
        ...timelineBuckets.map((bucket) {
          final bucketColor = _getBucketColor(bucket.name);
          final bucketIcon = _getBucketIcon(bucket.name);
          final tasks = bucket.tasks;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.015),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bucket Header
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: bucketColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(bucketIcon, size: 16, color: bucketColor),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        bucket.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${bucket.timeRange}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${tasks.length}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                // Tasks in this bucket
                if (tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'No tasks scheduled for ${bucket.name.toLowerCase()}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 44, endIndent: 12, color: Color(0xFFF8FAFC)),
                    itemBuilder: (context, idx) {
                      final task = tasks[idx];
                      final isDone = task.isCompleted;

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          onTap: () => EditTaskBottomSheet.show(context, task),
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          leading: GestureDetector(
                            onTap: () => onToggleComplete(task),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDone ? AppColors.accent : Colors.transparent,
                                border: Border.all(
                                  color: isDone ? AppColors.accent : AppColors.textSecondary.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: isDone
                                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                                  : null,
                            ),
                          ),
                          title: Text(
                            task.title,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              if (task.formattedDuration != null) ...[
                                Icon(Icons.timer_outlined, size: 11, color: AppColors.textSecondary),
                                const SizedBox(width: 2),
                                Text(
                                  task.formattedDuration!,
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (task.category != null)
                                Text(
                                  task.category!.name,
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: task.priority.backgroundColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  task.priority.label.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: task.priority.color,
                                  ),
                                ),
                              ),
                              if (!isViewingToday) ...[
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.today_rounded, size: 16, color: AppColors.accent),
                                  tooltip: 'Move to Today',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => onMoveToToday(task.id),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
