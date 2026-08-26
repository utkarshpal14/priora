import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/planner/domain/planner_model.dart';
import 'package:frontend/features/planner/presentation/controllers/planner_controller.dart';
import 'package:frontend/features/tasks/domain/task_model.dart';

class ScheduleTimeSlotDialog extends ConsumerStatefulWidget {
  final TaskModel task;
  final DateTime initialDate;
  final TaskSessionModel? sessionToEdit;

  const ScheduleTimeSlotDialog({
    super.key,
    required this.task,
    required this.initialDate,
    this.sessionToEdit,
  });

  static Future<void> show(
    BuildContext context, {
    required TaskModel task,
    required DateTime initialDate,
    TaskSessionModel? sessionToEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScheduleTimeSlotDialog(
        task: task,
        initialDate: initialDate,
        sessionToEdit: sessionToEdit,
      ),
    );
  }

  @override
  ConsumerState<ScheduleTimeSlotDialog> createState() => _ScheduleTimeSlotDialogState();
}

class _ScheduleTimeSlotDialogState extends ConsumerState<ScheduleTimeSlotDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _validationError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;

    if (widget.sessionToEdit != null) {
      final s = widget.sessionToEdit!;
      _selectedDate = s.scheduledStart.toLocal();
      _startTime = TimeOfDay(hour: s.scheduledStart.toLocal().hour, minute: s.scheduledStart.toLocal().minute);
      _endTime = TimeOfDay(hour: s.scheduledEnd.toLocal().hour, minute: s.scheduledEnd.toLocal().minute);
    } else {
      final now = TimeOfDay.now();
      _startTime = TimeOfDay(hour: (now.hour + 1).clamp(0, 23), minute: 0);
      _endTime = TimeOfDay(hour: (now.hour + 2).clamp(0, 23), minute: 0);
    }
  }

  DateTime _buildDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  int get _durationMinutes {
    final start = _buildDateTime(_selectedDate, _startTime);
    final end = _buildDateTime(_selectedDate, _endTime);
    return end.difference(start).inMinutes;
  }

  String get _formattedDuration {
    final mins = _durationMinutes;
    if (mins <= 0) return 'Invalid duration';
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  void _applyDurationPreset(int minutes) {
    final start = _buildDateTime(_selectedDate, _startTime);
    final newEnd = start.add(Duration(minutes: minutes));
    setState(() {
      _endTime = TimeOfDay(hour: newEnd.hour, minute: newEnd.minute);
      _validationError = null;
    });
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        // Adjust end time to preserve duration or at least +1 hour
        final startDt = _buildDateTime(_selectedDate, picked);
        final endDt = _buildDateTime(_selectedDate, _endTime);
        if (endDt.isBefore(startDt) || endDt == startDt) {
          final autoEnd = startDt.add(const Duration(hours: 1));
          _endTime = TimeOfDay(hour: autoEnd.hour, minute: autoEnd.minute);
        }
        _validationError = null;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
        _validationError = null;
      });
    }
  }

  List<String> _detectLocalConflicts(DailyPlanModel? plan) {
    if (plan == null) return [];
    final startDt = _buildDateTime(_selectedDate, _startTime);
    final endDt = _buildDateTime(_selectedDate, _endTime);

    final conflicts = <String>[];
    for (final s in plan.timeBlocks) {
      if (widget.sessionToEdit != null && s.id == widget.sessionToEdit!.id) {
        continue;
      }
      final sStart = s.scheduledStart.toLocal();
      final sEnd = s.scheduledEnd.toLocal();

      if (startDt.isBefore(sEnd) && sStart.isBefore(endDt)) {
        conflicts.add('${s.task?.title ?? "Another session"} (${s.formattedTimeRange})');
      }
    }
    return conflicts;
  }

  Future<void> _submit() async {
    final startDt = _buildDateTime(_selectedDate, _startTime);
    final endDt = _buildDateTime(_selectedDate, _endTime);

    if (endDt.isBefore(startDt) || endDt == startDt) {
      setState(() {
        _validationError = 'End time must be strictly after start time.';
      });
      return;
    }

    final navigator = Navigator.of(context);
    // Dismiss focus block modal instantly for ultra-fluid UI response
    navigator.pop();

    final plannerNotifier = ref.read(plannerControllerProvider.notifier);

    if (widget.sessionToEdit != null && !widget.sessionToEdit!.id.startsWith('auto_')) {
      final success = await plannerNotifier.updateSession(
        sessionId: widget.sessionToEdit!.id,
        taskId: widget.task.id,
        scheduledStart: startDt,
        scheduledEnd: endDt,
      );
      if (!success) {
        await plannerNotifier.createSession(
          taskId: widget.task.id,
          scheduledStart: startDt,
          scheduledEnd: endDt,
        );
      }
    } else {
      await plannerNotifier.createSession(
        taskId: widget.task.id,
        scheduledStart: startDt,
        scheduledEnd: endDt,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final plannerState = ref.watch(plannerControllerProvider);
    final conflicts = _detectLocalConflicts(plannerState.dailyPlan);
    final isEditing = widget.sessionToEdit != null;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Edit Focus Block' : 'Schedule Focus Block ⏰',
                    style: GoogleFonts.inter(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.task.title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? theme.colorScheme.secondary : AppColors.primary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date & Time Selector Row
          Row(
            children: [
              // Start Time Card
              Expanded(
                child: InkWell(
                  onTap: _pickStartTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'START TIME',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 16, color: isDark ? theme.colorScheme.secondary : AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              _startTime.format(context),
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.arrow_forward_rounded, size: 16, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
              const SizedBox(width: 10),

              // End Time Card
              Expanded(
                child: InkWell(
                  onTap: _pickEndTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'END TIME',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 16, color: theme.colorScheme.secondary),
                            const SizedBox(width: 6),
                            Text(
                              _endTime.format(context),
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Duration Presets & Duration Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Durations:',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _durationMinutes > 0
                      ? (isDark ? theme.colorScheme.secondary.withValues(alpha: 0.15) : const Color(0xFFE0E7FF))
                      : (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : const Color(0xFFFEE2E2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formattedDuration,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _durationMinutes > 0
                        ? (isDark ? theme.colorScheme.secondary : AppColors.primary)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [30, 60, 90, 120, 180].map((mins) {
              return ActionChip(
                label: Text(mins < 60 ? '${mins}m' : '${mins ~/ 60}h${mins % 60 != 0 ? ' ${mins % 60}m' : ''}'),
                labelStyle: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.transparent),
                ),
                onPressed: () => _applyDurationPreset(mins),
              );
            }).toList(),
          ),

          // Validation Error Alert
          if (_validationError != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _validationError!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Conflict Warning Alert
          if (conflicts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFFD97706) : const Color(0xFFFCD34D)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Time conflict: Overlaps with ${conflicts.join(", ")}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? theme.colorScheme.secondary : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      isEditing ? 'Update Focus Block' : 'Schedule Focus Block',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
