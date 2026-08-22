import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/planner/domain/planner_model.dart';
import 'package:frontend/features/planner/presentation/widgets/schedule_time_slot_dialog.dart';
import 'package:frontend/features/tasks/domain/task_model.dart';

class HourlyTimelineSection extends StatelessWidget {
  final List<TaskSessionModel> timeBlocks;
  final List<TaskModel> unscheduledTasks;
  final bool isViewingToday;
  final DateTime selectedDate;
  final Function(String sessionId) onDeleteSession;
  final Function(TaskModel task) onToggleTaskComplete;
  final Function(TaskModel task) onStartTask;

  const HourlyTimelineSection({
    super.key,
    required this.timeBlocks,
    required this.unscheduledTasks,
    required this.isViewingToday,
    required this.selectedDate,
    required this.onDeleteSession,
    required this.onToggleTaskComplete,
    required this.onStartTask,
  });

  Widget _buildCurrentTimeIndicator() {
    final now = DateTime.now();
    final timeStr = DateFormat('h:mm a').format(now);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$timeStr  NOW',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0x33EF4444)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBlockCard(BuildContext context, TaskSessionModel session) {
    final task = session.task;
    final isCompleted = task?.isCompleted ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: session.hasConflict
              ? const Color(0xFFFCD34D)
              : (isCompleted ? const Color(0xFF86EFAC) : Colors.black.withValues(alpha: 0.06)),
          width: session.hasConflict || isCompleted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Time Slot Column
            Container(
              width: 82,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: session.hasConflict ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('h:mm a').format(session.scheduledStart.toLocal()),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 8,
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                  Text(
                    DateFormat('h:mm a').format(session.scheduledEnd.toLocal()),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.formattedDuration,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Middle Content: Title, Priority, Conflicts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (task != null)
                        GestureDetector(
                          onTap: () => onToggleTaskComplete(task),
                          child: Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isCompleted ? AppColors.accent : Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: isCompleted ? AppColors.accent : Colors.black.withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                            ),
                            child: isCompleted
                                ? const Icon(Icons.check, size: 13, color: Colors.white)
                                : null,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          task?.title ?? 'Scheduled Session',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Category & Priority
                  Row(
                    children: [
                      if (task?.category != null) ...[
                        Text(
                          task!.category!.name,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (task != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: task.priority.backgroundColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task.priority.label.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: task.priority.color,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Conflict Alert Badge
                  if (session.hasConflict) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFD97706)),
                          const SizedBox(width: 4),
                          Text(
                            'Overlap: ${session.conflictingWith.join(", ")}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Actions (Focus Start / Edit / Delete)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (task != null && !isCompleted) ...[
                  GestureDetector(
                    onTap: () {
                      onStartTask(task);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Focus session started for "${task.title}"! ⏱️'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 2),
                          Text(
                            'Focus',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  onSelected: (val) {
                    if (val == 'edit' && task != null) {
                      ScheduleTimeSlotDialog.show(
                        context,
                        task: task,
                        initialDate: selectedDate,
                        sessionToEdit: session,
                      );
                    } else if (val == 'delete') {
                      onDeleteSession(session.id);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Edit Slot', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Remove Slot', style: TextStyle(fontSize: 13, color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Hourly Schedule',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (timeBlocks.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${timeBlocks.length} focus block${timeBlocks.length > 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Real-Time Moving Current Time Marker (when viewing today)
        if (isViewingToday) _buildCurrentTimeIndicator(),

        // Scheduled Time Blocks
        if (timeBlocks.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Center(
              child: Text(
                'No hourly focus blocks scheduled for this day.\nAssign a time slot to any task below to plan your hours.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          )
        else
          ...timeBlocks.map((b) => _buildTimeBlockCard(context, b)),

        const SizedBox(height: 14),

        // Unscheduled / Ready to Time-Block Tasks Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.format_list_bulleted_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Ready to Schedule (${unscheduledTasks.length})',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        if (unscheduledTasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'All tasks for today have been assigned focus slots! 🚀',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          ...unscheduledTasks.map((t) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                t.formattedDeadline,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: t.isOverdue ? const Color(0xFFDC2626) : AppColors.textSecondary,
                                  fontWeight: t.isOverdue ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                              if (t.formattedDuration != null) ...[
                                Text(' • ', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                                Text(
                                  t.formattedDuration!,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => ScheduleTimeSlotDialog.show(
                        context,
                        task: t,
                        initialDate: selectedDate,
                      ),
                      icon: const Icon(Icons.access_time_rounded, size: 14),
                      label: const Text('Schedule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                        textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
