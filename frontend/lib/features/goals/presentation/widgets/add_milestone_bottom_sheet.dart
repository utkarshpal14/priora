import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/goals/presentation/controllers/goals_controller.dart';

class AddMilestoneBottomSheet extends ConsumerStatefulWidget {
  final String goalId;
  final int nextOrderIndex;

  const AddMilestoneBottomSheet({
    super.key,
    required this.goalId,
    required this.nextOrderIndex,
  });

  static Future<void> show(BuildContext context, {required String goalId, required int nextOrderIndex}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMilestoneBottomSheet(goalId: goalId, nextOrderIndex: nextOrderIndex),
    );
  }

  @override
  ConsumerState<AddMilestoneBottomSheet> createState() => _AddMilestoneBottomSheetState();
}

class _AddMilestoneBottomSheetState extends ConsumerState<AddMilestoneBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _targetDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: theme.colorScheme.secondary,
                    onPrimary: Colors.white,
                    surface: const Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppColors.textPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);
    navigator.pop();

    final payload = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      'target_date': _targetDate != null ? DateFormat('yyyy-MM-dd').format(_targetDate!) : null,
      'order_index': widget.nextOrderIndex,
    };

    final goalsNotifier = ref.read(goalsControllerProvider.notifier);
    await goalsNotifier.addMilestone(widget.goalId, payload);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal grab handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Milestone Checkpoint',
                  style: GoogleFonts.inter(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              autofocus: true,
              style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Milestone Title',
                labelStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                hintText: 'e.g. Phase 2: Graphs & Dynamic Programming',
                hintStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF64748B) : AppColors.textSecondary.withValues(alpha: 0.7)),
                prefixIcon: Icon(Icons.flag_rounded, color: isDark ? theme.colorScheme.secondary : AppColors.primary),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.12)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? theme.colorScheme.secondary : AppColors.primary, width: 1.5),
                ),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Please enter milestone title' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descController,
              maxLines: 2,
              style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Notes / Scope (Optional)',
                labelStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                hintText: 'What constitutes completing this milestone?',
                hintStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF64748B) : AppColors.textSecondary.withValues(alpha: 0.7)),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.12)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? theme.colorScheme.secondary : AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: isDark ? theme.colorScheme.secondary : AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      _targetDate != null
                          ? 'Target Date: ${DateFormat('MMM d, yyyy').format(_targetDate!)}'
                          : 'Set Target Date (Optional)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _targetDate != null ? (isDark ? Colors.white : AppColors.textPrimary) : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? theme.colorScheme.secondary : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Add Milestone',
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
