import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/review/domain/review_model.dart';
import 'package:frontend/features/review/presentation/controllers/review_controller.dart';
import 'package:frontend/features/review/presentation/widgets/review_celebration_dialog.dart';
import 'package:frontend/features/review/presentation/widgets/review_task_action_card.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reviewState = ref.watch(reviewControllerProvider);
    final reviewNotifier = ref.read(reviewControllerProvider.notifier);
    final summary = reviewState.summary;

    final completedTasks = summary?.completedTasks ?? [];
    final incompleteTasks = summary?.incompleteTasks ?? [];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Daily Review 🌅',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary, size: 20),
            onPressed: () => reviewNotifier.loadReview(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: summary != null && incompleteTasks.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: reviewState.isSubmitting
                        ? null
                        : () async {
                            final success = await reviewNotifier.applyBatchReschedule();
                            if (success && context.mounted && summary != null) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => ReviewCelebrationDialog(
                                  summary: summary,
                                  rescheduledCount: reviewState.stagedCount,
                                  onDismiss: () => reviewNotifier.dismissCelebration(),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? theme.colorScheme.secondary : AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: reviewState.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            reviewState.stagedCount > 0
                                ? 'Apply Actions (${reviewState.stagedCount}/${incompleteTasks.length})'
                                : 'Wrap Up Day',
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            )
          : null,
      body: reviewState.isLoading && summary == null
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.secondary))
          : RefreshIndicator(
              onRefresh: () => reviewNotifier.loadReview(),
              color: theme.colorScheme.secondary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Review Header Stats Card
                    if (summary != null)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
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
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Today's Wrap-Up",
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${summary.completedCount} completed • ${summary.incompleteCount} rollover',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (summary.totalCompletedMinutes > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.timer_outlined, size: 13, color: Color(0xFFD97706)),
                                        const SizedBox(width: 4),
                                        Text(
                                          summary.formattedCompletedDuration,
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (summary.completionRate / 100.0).clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                valueColor: AlwaysStoppedAnimation<Color>(isDark ? theme.colorScheme.secondary : AppColors.accent),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (summary.overdueCount > 0)
                                  Text(
                                    '${summary.overdueCount} overdue',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFDC2626),
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                                Text(
                                  '${summary.completionRate.toInt()}% Completed',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // Section 1: Completed Tasks (Wins)
                    if (completedTasks.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 16, color: isDark ? theme.colorScheme.secondary : AppColors.accent),
                            const SizedBox(width: 6),
                            Text(
                              "Today's Wins (${completedTasks.length})",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...completedTasks.map((t) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_rounded, size: 16, color: isDark ? theme.colorScheme.secondary : AppColors.accent),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    t.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: isDark ? const Color(0xFF64748B) : AppColors.textSecondary,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                                if (t.formattedDuration != null)
                                  Text(
                                    t.formattedDuration!,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],

                    // Section 2: Incomplete Work & Rollovers
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.pending_actions_rounded, size: 16, color: Color(0xFFD97706)),
                              const SizedBox(width: 6),
                              Text(
                                "Unfinished Tasks (${incompleteTasks.length})",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (incompleteTasks.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                for (final t in incompleteTasks) {
                                  reviewNotifier.stageAction(t.id, RescheduleAction.moveTomorrow);
                                }
                              },
                              child: Text(
                                'All to Tomorrow',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? theme.colorScheme.secondary : AppColors.accent,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    if (incompleteTasks.isEmpty)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Text('✨', style: TextStyle(fontSize: 32)),
                              const SizedBox(height: 10),
                              Text(
                                'All tasks completed for today!',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'No unfinished work remaining to reschedule.',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...incompleteTasks.map((t) {
                        final staged = reviewState.stagedActions[t.id];
                        return ReviewTaskActionCard(
                          task: t,
                          stagedAction: staged,
                          onSelectAction: (action, {customDeadline}) =>
                              reviewNotifier.stageAction(t.id, action, customDeadline: customDeadline),
                          onClearAction: () => reviewNotifier.unstageAction(t.id),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }
}
