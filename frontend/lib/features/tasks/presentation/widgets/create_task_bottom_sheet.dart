import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../reminders/domain/reminder_model.dart';
import '../../domain/task_model.dart';
import '../controllers/tasks_controller.dart';

class CreateTaskBottomSheet extends ConsumerStatefulWidget {
  final String? goalId;
  final String? milestoneId;

  const CreateTaskBottomSheet({
    super.key,
    this.goalId,
    this.milestoneId,
  });

  static Future<void> show(
    BuildContext context, {
    String? goalId,
    String? milestoneId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTaskBottomSheet(
        goalId: goalId,
        milestoneId: milestoneId,
      ),
    );
  }

  @override
  ConsumerState<CreateTaskBottomSheet> createState() => _CreateTaskBottomSheetState();
}

class _CreateTaskBottomSheetState extends ConsumerState<CreateTaskBottomSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  TaskPriority _selectedPriority = TaskPriority.medium;
  String? _selectedCategoryId;
  String? _selectedGoalId;
  String? _selectedMilestoneId;
  DateTime? _selectedDeadline;
  ReminderPreset _selectedReminderPreset = ReminderPreset.none;
  DateTime? _customReminderTime;
  String _selectedRepeatType = 'none';
  bool _showDescriptionField = false;

  @override
  void initState() {
    super.initState();
    _selectedGoalId = widget.goalId;
    _selectedMilestoneId = widget.milestoneId;

    // Default deadline: Today 6:00 PM (if before 6 PM) or Tomorrow 6:00 PM
    final now = DateTime.now();
    if (now.hour >= 18) {
      final tomorrow = now.add(const Duration(days: 1));
      _selectedDeadline = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 18, 0);
    } else {
      _selectedDeadline = DateTime(now.year, now.month, now.day, 18, 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  DateTime? _getEffectiveRemindAt() {
    if (_selectedReminderPreset == ReminderPreset.none) return null;
    if (_selectedReminderPreset == ReminderPreset.custom) return _customReminderTime;
    return _selectedReminderPreset.calculateRemindAt(_selectedDeadline);
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDeadline ?? now),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDeadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          // Auto-enable 15-minute reminder preset if no preset is selected yet
          if (_selectedReminderPreset == ReminderPreset.none) {
            _selectedReminderPreset = ReminderPreset.fifteenMinutes;
          }
          if (_selectedReminderPreset != ReminderPreset.custom) {
            _customReminderTime =
                _selectedReminderPreset.calculateRemindAt(_selectedDeadline);
          }
        });
      }
    }
  }

  Future<void> _pickCustomReminderTime() async {
    final now = DateTime.now();
    final maxDate = _selectedDeadline ?? now.add(const Duration(days: 365));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _customReminderTime ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: maxDate,
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_customReminderTime ?? now),
      );

      if (pickedTime != null && mounted) {
        final candidate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _selectedReminderPreset = ReminderPreset.custom;
          _customReminderTime = candidate;
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);
    final categories = ref.read(tasksControllerProvider).categories;
    final catId = _selectedCategoryId ?? (categories.isNotEmpty ? categories.first.id : null);

    // Dismiss bottom sheet instantly for ultra-fluid UI response
    navigator.pop();

    await ref.read(tasksControllerProvider.notifier).createTask(
          title: _titleController.text.trim(),
          description: _showDescriptionField && _descController.text.trim().isNotEmpty
              ? _descController.text.trim()
              : null,
          priority: _selectedPriority,
          categoryId: catId,
          goalId: _selectedGoalId,
          milestoneId: _selectedMilestoneId,
          deadline: _selectedDeadline,
          remindAt: _getEffectiveRemindAt(),
          repeatType: _selectedRepeatType,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tasksState = ref.watch(tasksControllerProvider);
    final categories = tasksState.categories;

    // Set default category if not selected
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: bottomInset + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modal Grab Handle & Title
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
                    'Create New Task',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title Input Field
              TextFormField(
                controller: _titleController,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'What needs to be done?',
                  hintStyle: GoogleFonts.inter(
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a task title.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Priority Selector
              Text(
                'Priority',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: TaskPriority.values.map((p) {
                  final isSelected = _selectedPriority == p;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPriority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? p.backgroundColor : (isDark ? const Color(0xFF0F172A) : Colors.white),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? p.color : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.1)),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              p.label,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? p.color : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Category & Deadline Row
              Row(
                children: [
                  // Category Dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedCategoryId,
                              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary),
                              items: categories.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c.id,
                                  child: Text(
                                    c.name,
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCategoryId = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Deadline Picker Button
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due Date',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDeadline,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded,
                                    size: 15, color: theme.colorScheme.secondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedDeadline != null
                                        ? DateFormat('MMM d, h:mm a').format(_selectedDeadline!)
                                        : 'Set deadline',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Reminder Presets Selector
              Text(
                'Reminder',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ReminderPreset.values.map((preset) {
                    final isSelected = _selectedReminderPreset == preset;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () {
                          if (preset == ReminderPreset.custom) {
                            _pickCustomReminderTime();
                          } else {
                            setState(() {
                              _selectedReminderPreset = preset;
                              _customReminderTime =
                                  preset.calculateRemindAt(_selectedDeadline);
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFEF3C7))
                                : (isDark ? const Color(0xFF0F172A) : Colors.white),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFD97706)
                                  : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.1)),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_none_rounded,
                                size: 14,
                                color: isSelected
                                    ? const Color(0xFFD97706)
                                    : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                preset == ReminderPreset.custom && _customReminderTime != null
                                    ? DateFormat('MMM d, h:mm a').format(_customReminderTime!)
                                    : preset.label,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected
                                      ? (isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E))
                                      : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Recurrence / Repeat Selector (ENH-005)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.repeat_rounded,
                        size: 16,
                        color: _selectedRepeatType != 'none'
                            ? (isDark ? theme.colorScheme.secondary : AppColors.primary)
                            : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Repeat',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (_selectedRepeatType != 'none')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDark ? theme.colorScheme.secondary : AppColors.primary).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _selectedRepeatType.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? theme.colorScheme.secondary : AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    {'id': 'none', 'label': 'Never'},
                    {'id': 'daily', 'label': 'Daily'},
                    {'id': 'weekly', 'label': 'Weekly'},
                    {'id': 'monthly', 'label': 'Monthly'},
                  ].map((option) {
                    final isSelected = _selectedRepeatType == option['id'];
                    final accentColor = isDark ? theme.colorScheme.secondary : AppColors.primary;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            _selectedRepeatType = option['id']!;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentColor.withValues(alpha: 0.15)
                                : (isDark ? const Color(0xFF0F172A) : Colors.white),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? accentColor
                                  : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.1)),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            option['label']!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? accentColor
                                  : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Optional Description Toggle
              if (!_showDescriptionField)
                GestureDetector(
                  onTap: () => setState(() => _showDescriptionField = true),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline, size: 16, color: theme.colorScheme.secondary),
                      const SizedBox(width: 6),
                      Text(
                        'Add details / description',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  'Description (Optional)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Add extra context or notes...',
                    hintStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.1)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: tasksState.isCreating ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? theme.colorScheme.secondary : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: tasksState.isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Create Task',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
