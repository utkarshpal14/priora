import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/goals/domain/goal_model.dart';

class GoalCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback onTap;

  const GoalCard({
    super.key,
    required this.goal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = (goal.progressPercentage / 100.0).clamp(0.0, 1.0);
    final daysRemaining = goal.daysRemaining;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: goal.displayColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          goal.category?.name ?? 'General',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: goal.status.color.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        goal.status.label,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: goal.status.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Goal Title
                Text(
                  goal.title,
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),

                // Description (if present)
                if (goal.description != null && goal.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    goal.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Progress Bar & Percentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(goal.displayColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${goal.progressPercentage.toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bottom Meta: Milestones, Tasks & Target Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (goal.milestonesCount > 0) ...[
                          Icon(Icons.flag_rounded, size: 13, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            '${goal.completedMilestonesCount}/${goal.milestonesCount}',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (goal.tasksCount > 0) ...[
                          Icon(Icons.check_box_outlined, size: 13, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            '${goal.completedTasksCount}/${goal.tasksCount}',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (goal.attachmentCount > 0) ...[
                          const Icon(Icons.attach_file_rounded, size: 13, color: Color(0xFF6366F1)),
                          const SizedBox(width: 2),
                          Text(
                            '${goal.attachmentCount} Resource${goal.attachmentCount > 1 ? 's' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (goal.formattedTargetDate != null)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: daysRemaining != null && daysRemaining < 0
                                ? const Color(0xFFDC2626)
                                : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            daysRemaining != null
                                ? (daysRemaining < 0
                                    ? 'Overdue'
                                    : daysRemaining == 0
                                        ? 'Due Today'
                                        : '$daysRemaining days left')
                                : goal.formattedTargetDate!,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: daysRemaining != null && daysRemaining < 0
                                  ? const Color(0xFFDC2626)
                                  : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
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
  }
}
