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
                  const Icon(Icons.date_range_rounded, size: 18, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    "Weekly Overview",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${weeklyPlan.completedTasks}/${weeklyPlan.totalTasks} Done',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: day.hasCritical
                        ? const Color(0xFFFCA5A5)
                        : Colors.black.withValues(alpha: 0.06),
                    width: day.hasCritical ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
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
                                  color: AppColors.textPrimary,
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
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Text(
                                'Due: ',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${day.dueCount}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: day.dueCount > 0 ? AppColors.accent : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Done: ${day.completedCount}',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
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
