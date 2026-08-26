import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/planner/domain/planner_model.dart';

class WeeklyPreviewSection extends StatelessWidget {
  final WeeklyPlanModel weeklyPlan;
  final ValueChanged<DateTime> onSelectDate;

  const WeeklyPreviewSection({
    super.key,
    required this.weeklyPlan,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    if (weeklyPlan.days.isEmpty) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.date_range_rounded, size: 18, color: theme.colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text(
                    "Weekly Overview",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${weeklyPlan.completedTasks}/${weeklyPlan.totalTasks} Done',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          height: 106,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: weeklyPlan.days.length,
            itemBuilder: (context, index) {
              final day = weeklyPlan.days[index];
              DateTime parsedDate;
              try {
                parsedDate = DateTime.parse(day.date);
              } catch (_) {
                parsedDate = DateTime.now();
              }

              return Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: day.hasCritical
                        ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5))
                        : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
                    width: day.hasCritical ? 1.5 : 1,
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
                  child: InkWell(
                    onTap: () => onSelectDate(parsedDate),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                day.dayName.substring(0, 3).toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              if (day.hasCritical)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDC2626),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            day.date.split('-').sublist(1).join('/'),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Text(
                                'Due: ',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${day.dueCount}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: day.dueCount > 0 ? theme.colorScheme.secondary : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Done: ${day.completedCount}',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
