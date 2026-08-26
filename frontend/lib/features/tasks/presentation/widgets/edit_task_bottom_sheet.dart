import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../attachments/presentation/widgets/resource_section_widget.dart';
import '../../../reminders/domain/reminder_model.dart';
import '../../domain/task_model.dart';
import '../controllers/tasks_controller.dart';

class EditTaskBottomSheet extends ConsumerStatefulWidget {
  final TaskModel task;

  const EditTaskBottomSheet({
    super.key,
    required this.task,
  });

  static Future<void> show(BuildContext context, TaskModel task) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditTaskBottomSheet(task: task),
    );
  }

  @override
  ConsumerState<EditTaskBottomSheet> createState() => _EditTaskBottomSheetState();
}

class _EditTaskBottomSheetState extends ConsumerState<EditTaskBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  final _formKey = GlobalKey<FormState>();

  late TaskPriority _selectedPriority;
  late String? _selectedCategoryId;
  late DateTime? _selectedDeadline;
  late String _selectedRepeatType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description ?? '');
    _selectedPriority = widget.task.priority;
    _selectedCategoryId = widget.task.categoryId;
    _selectedDeadline = widget.task.deadline?.toLocal();
    _selectedRepeatType = widget.task.repeatType.isNotEmpty
        ? widget.task.repeatType.toLowerCase()
        : 'none';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now.add(const Duration(days: 365 * 3)),
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
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);
    navigator.pop();

    await ref.read(tasksControllerProvider.notifier).updateTask(
          taskId: widget.task.id,
          title: _titleController.text.trim(),
          description: _descController.text.trim().isNotEmpty
              ? _descController.text.trim()
              : '',
          priority: _selectedPriority,
          categoryId: _selectedCategoryId,
          deadline: _selectedDeadline,
          repeatType: _selectedRepeatType,
        );
  }

  Future<void> _handleToggleCompletion() async {
    await ref.read(tasksControllerProvider.notifier).toggleTaskCompletion(widget.task);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDelete() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Task',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this task? This action cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      await ref.read(tasksControllerProvider.notifier).deleteTask(widget.task.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tasksState = ref.watch(tasksControllerProvider);
    final categories = tasksState.categories;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isCompleted = widget.task.isCompleted;

    final createdAtStr = widget.task.createdAt != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(widget.task.createdAt!.toLocal())
        : 'Unknown';

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
              // Grab Handle
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

              // Header: Title & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Task',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      // Delete Icon Button
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 22,
                          color: Color(0xFFDC2626),
                        ),
                        tooltip: 'Delete task',
                        onPressed: _confirmDelete,
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 20, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title Field
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  labelStyle: GoogleFonts.inter(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.12)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.1)),
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
                            child: DropdownButton<String?>(
                              isExpanded: true,
                              value: _selectedCategoryId,
                              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('No Category'),
                                ),
                                ...categories.map((c) {
                                  return DropdownMenuItem<String?>(
                                    value: c.id,
                                    child: Text(
                                      c.name,
                                      style: GoogleFonts.inter(fontSize: 13),
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedCategoryId = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Deadline Picker
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Due Date',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            if (_selectedDeadline != null)
                              GestureDetector(
                                onTap: () => setState(() => _selectedDeadline = null),
                                child: Text(
                                  'Clear',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFFDC2626),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
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
                                      color: _selectedDeadline != null
                                          ? (isDark ? Colors.white : AppColors.textPrimary)
                                          : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
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

              // Reminders Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reminders (${widget.task.reminders.length}/5)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // List existing active reminders
              if (widget.task.reminders.isNotEmpty) ...[
                Column(
                  children: widget.task.reminders.map((rem) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: rem.isScheduled
                              ? const Color(0xFFD97706).withValues(alpha: 0.3)
                              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            rem.isScheduled
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_off_outlined,
                            size: 15,
                            color: rem.isScheduled
                                ? const Color(0xFFD97706)
                                : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${rem.formattedRemindAt} (${rem.status})',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: rem.isScheduled
                                    ? (isDark ? Colors.white : AppColors.textPrimary)
                                    : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Color(0xFFDC2626)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Remove reminder',
                            onPressed: () async {
                              await ref
                                  .read(tasksControllerProvider.notifier)
                                  .deleteReminder(
                                    taskId: widget.task.id,
                                    reminderId: rem.id,
                                    notificationId: rem.notificationId,
                                  );
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
              ],

              // Quick Add Preset Chips (if < 5 reminders)
              if (widget.task.reminders.length < 5) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ReminderPreset.values
                        .where((p) => p != ReminderPreset.none)
                        .map((preset) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () async {
                            DateTime? targetTime;
                            if (preset == ReminderPreset.custom) {
                              final now = DateTime.now();
                              final maxDate = _selectedDeadline ?? now.add(const Duration(days: 365));
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: now.add(const Duration(hours: 1)),
                                firstDate: now,
                                lastDate: maxDate,
                              );
                              if (pickedDate != null && context.mounted) {
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (pickedTime != null) {
                                  targetTime = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                }
                              }
                            } else {
                              targetTime = preset.calculateRemindAt(_selectedDeadline);
                            }

                            if (targetTime != null && context.mounted) {
                              if (_selectedDeadline != null &&
                                  targetTime.isAfter(_selectedDeadline!)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Reminder cannot be scheduled after deadline.'),
                                    backgroundColor: Color(0xFFDC2626),
                                  ),
                                );
                                return;
                              }
                              await ref
                                  .read(tasksControllerProvider.notifier)
                                  .addReminderToTask(
                                    taskId: widget.task.id,
                                    taskTitle: widget.task.title,
                                    remindAt: targetTime,
                                    formattedDeadline: widget.task.formattedDeadline,
                                  );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_alarm_rounded,
                                    size: 13, color: theme.colorScheme.secondary),
                                const SizedBox(width: 4),
                                Text(
                                  '+ ${preset.label}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
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
              ],
              const SizedBox(height: 16),

              // Resources & Attachments Section
              ResourceSectionWidget(taskId: widget.task.id),
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

              // Description Field
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
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDark ? theme.colorScheme.secondary : AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Read-only Metadata: Created At
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Created $createdAtStr',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons: Save Changes & Complete/Reopen
              Row(
                children: [
                  // Complete/Reopen button
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: _handleToggleCompletion,
                      icon: Icon(
                        isCompleted ? Icons.restart_alt_rounded : Icons.check_circle_outline_rounded,
                        size: 18,
                        color: isCompleted ? (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary) : theme.colorScheme.secondary,
                      ),
                      label: Text(
                        isCompleted ? 'Reopen' : 'Complete',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary) : theme.colorScheme.secondary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isCompleted ? (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.15)) : theme.colorScheme.secondary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Save Changes button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? theme.colorScheme.secondary : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
