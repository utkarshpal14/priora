import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/review/domain/review_model.dart';
import 'package:frontend/features/tasks/domain/task_model.dart';

class ReviewTaskActionCard extends StatelessWidget {
  final TaskModel task;
  final RescheduleItemModel? stagedAction;
  final Function(RescheduleAction, {DateTime? customDeadline}) onSelectAction;
  final VoidCallback onClearAction;

  const ReviewTaskActionCard({
    super.key,
    required this.task,
    required this.stagedAction,
    required this.onSelectAction,
    required this.onClearAction,
  });

  Future<void> _pickCustomDate(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 2)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && context.mounted) {
      final hour = task.deadline?.hour ?? 18;
      final minute = task.deadline?.minute ?? 0;
      final fullDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, hour, minute);
      onSelectAction(RescheduleAction.schedule, customDeadline: fullDateTime);
    }
  }

  Widget _buildActionChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required RescheduleAction action,
    required bool isSelected,
    Color activeColor = AppColors.primary,
    VoidCallback? customTap,
  }) {
    return GestureDetector(
      onTap: customTap ?? () {
        if (isSelected) {
          onClearAction();
        } else {
          onSelectAction(action);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedAction = stagedAction?.action;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selectedAction != null
              ? AppColors.primary.withValues(alpha: 0.4)
              : (task.isOverdue ? const Color(0xFFFCA5A5) : Colors.black.withValues(alpha: 0.06)),
          width: selectedAction != null || task.isOverdue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Priority Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (task.isOverdue) ...[
                          const Icon(Icons.error_outline_rounded, size: 12, color: Color(0xFFDC2626)),
                          const SizedBox(width: 3),
                          Text(
                            task.formattedDeadline,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ] else ...[
                          Text(
                            task.formattedDeadline,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (task.formattedDuration != null) ...[
                          Text(' • ', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                          Text(
                            task.formattedDuration!,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: task.priority.backgroundColor,
                  borderRadius: BorderRadius.circular(6),
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
            ],
          ),
          const SizedBox(height: 12),

          // Action Chips Row
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildActionChip(
                context: context,
                label: 'Tomorrow',
                icon: Icons.arrow_forward_rounded,
                action: RescheduleAction.moveTomorrow,
                isSelected: selectedAction == RescheduleAction.moveTomorrow,
              ),
              _buildActionChip(
                context: context,
                label: 'Next Week',
                icon: Icons.fast_forward_rounded,
                action: RescheduleAction.moveNextWeek,
                isSelected: selectedAction == RescheduleAction.moveNextWeek,
              ),
              _buildActionChip(
                context: context,
                label: stagedAction?.newDeadline != null
                    ? DateFormat('MMM d').format(stagedAction!.newDeadline!)
                    : 'Pick Date',
                icon: Icons.calendar_month_rounded,
                action: RescheduleAction.schedule,
                isSelected: selectedAction == RescheduleAction.schedule,
                customTap: () => _pickCustomDate(context),
              ),
              _buildActionChip(
                context: context,
                label: 'Done',
                icon: Icons.check_circle_outline_rounded,
                action: RescheduleAction.complete,
                isSelected: selectedAction == RescheduleAction.complete,
                activeColor: AppColors.accent,
              ),
              _buildActionChip(
                context: context,
                label: 'Cancel',
                icon: Icons.cancel_outlined,
                action: RescheduleAction.cancel,
                isSelected: selectedAction == RescheduleAction.cancel,
                activeColor: const Color(0xFF64748B),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
