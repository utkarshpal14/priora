import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/review/domain/review_model.dart';

class ReviewCelebrationDialog extends StatelessWidget {
  final ReviewSummaryModel summary;
  final int rescheduledCount;
  final VoidCallback onDismiss;

  const ReviewCelebrationDialog({
    super.key,
    required this.summary,
    required this.rescheduledCount,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebration Icon
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '🎉',
                  style: TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title & Encouragement
            Text(
              'Day Wrapped Up!',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Great job closing out your day. Your tomorrow is organized and ready to go.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),

            // Stats Recap Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${summary.completedCount}',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Completed',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                  Column(
                    children: [
                      Text(
                        '$rescheduledCount',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rescheduled',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (summary.totalCompletedMinutes > 0) ...[
                    Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                    Column(
                      children: [
                        Text(
                          summary.formattedCompletedDuration,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Focus Time',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Back to Tasks / Planner Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  onDismiss();
                  Navigator.of(context).pop();
                  context.go('/planner');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Back to Planner',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
