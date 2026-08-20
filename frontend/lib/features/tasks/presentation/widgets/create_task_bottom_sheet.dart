import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../reminders/domain/reminder_model.dart';
import '../../domain/task_model.dart';
import '../controllers/tasks_controller.dart';

class CreateTaskBottomSheet extends ConsumerStatefulWidget {
  const CreateTaskBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateTaskBottomSheet(),
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
  bool _showDescriptionField = false;

  @override
  void initState() {
    super.initState();
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
          // Recalculate preset reminder time if preset is active
          if (_selectedReminderPreset != ReminderPreset.none &&
              _selectedReminderPreset != ReminderPreset.custom) {
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

    final categories = ref.read(tasksControllerProvider).categories;
    final catId = _selectedCategoryId ?? (categories.isNotEmpty ? categories.first.id : null);

    final success = await ref.read(tasksControllerProvider.notifier).createTask(
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
        );

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      final error = ref.read(tasksControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to create task.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksControllerProvider);
    final categories = tasksState.categories;

    // Set default category if not selected
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: Colors.black.withValues(alpha: 0.15),
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title Input Field
              TextFormField(
                controller: _titleController,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'What needs to be done?',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
                  color: AppColors.textPrimary,
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
                            color: isSelected ? p.backgroundColor : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? p.color : Colors.black.withValues(alpha: 0.1),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              p.label,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? p.color : AppColors.textSecondary,
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
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedCategoryId,
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
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDeadline,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 15, color: AppColors.accent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedDeadline != null
                                        ? DateFormat('MMM d, h:mm a').format(_selectedDeadline!)
                                        : 'Set deadline',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
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
                  color: AppColors.textPrimary,
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
                            color: isSelected ? const Color(0xFFFEF3C7) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFD97706)
                                  : Colors.black.withValues(alpha: 0.1),
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
                                    : AppColors.textSecondary,
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
                                      ? const Color(0xFF92400E)
                                      : AppColors.textSecondary,
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

              // Optional Description Toggle
              if (!_showDescriptionField)
                GestureDetector(
                  onTap: () => setState(() => _showDescriptionField = true),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_circle_outline, size: 16, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(
                        'Add details / description',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accent,
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
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Add extra context or notes...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
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
                    backgroundColor: AppColors.primary,
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
