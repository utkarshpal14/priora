import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:frontend/core/constants/app_colors.dart';

class CalendarStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Map<String, int> taskCountByDate;

  const CalendarStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.taskCountByDate = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Render 14-day rolling window: 3 days past, today, 10 days future
    final startDate = today.subtract(const Duration(days: 3));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Selected Date Title + "Today" Quick Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d').format(selectedDate),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                if (selectedDate.year != today.year ||
                    selectedDate.month != today.month ||
                    selectedDate.day != today.day)
                  GestureDetector(
                    onTap: () => onDateSelected(today),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Jump to Today',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Date Item Strip
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 14,
              itemBuilder: (context, index) {
                final date = startDate.add(Duration(days: index));
                final isSelected = date.year == selectedDate.year &&
                    date.month == selectedDate.month &&
                    date.day == selectedDate.day;
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final dateKey = DateFormat('yyyy-MM-dd').format(date);
                final taskCount = taskCountByDate[dateKey] ?? 0;

                final selectedColor = isDark ? theme.colorScheme.secondary : AppColors.primary;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => onDateSelected(date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? selectedColor
                            : (isToday
                                ? theme.colorScheme.secondary.withValues(alpha: isDark ? 0.18 : 0.08)
                                : (isDark ? const Color(0xFF1E293B) : Colors.white)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? selectedColor
                              : (isToday
                                  ? theme.colorScheme.secondary.withValues(alpha: 0.4)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.06))),
                          width: isSelected || isToday ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: selectedColor.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('E').format(date).toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date.day.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : (isToday
                                      ? theme.colorScheme.secondary
                                      : (isDark ? Colors.white : AppColors.textPrimary)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (taskCount > 0)
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : (taskCount > 2
                                        ? const Color(0xFFDC2626)
                                        : theme.colorScheme.secondary),
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            const SizedBox(height: 5),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
