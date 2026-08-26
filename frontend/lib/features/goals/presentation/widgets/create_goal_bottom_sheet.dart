import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/features/goals/domain/goal_model.dart';
import 'package:frontend/features/goals/presentation/controllers/goals_controller.dart';
import 'package:frontend/features/tasks/presentation/controllers/tasks_controller.dart';

class CreateGoalBottomSheet extends ConsumerStatefulWidget {
  final GoalModel? goalToEdit;

  const CreateGoalBottomSheet({super.key, this.goalToEdit});

  static Future<void> show(BuildContext context, {GoalModel? goalToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateGoalBottomSheet(goalToEdit: goalToEdit),
    );
  }

  @override
  ConsumerState<CreateGoalBottomSheet> createState() => _CreateGoalBottomSheetState();
}

class _CreateGoalBottomSheetState extends ConsumerState<CreateGoalBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;

  String? _selectedCategoryId;
  DateTime? _targetDate;
  String _selectedColor = '#6366F1';
  GoalStatus _selectedStatus = GoalStatus.inProgress;

  final List<Map<String, dynamic>> _milestones = [];

  final List<String> _colorPalette = [
    '#6366F1', // Indigo
    '#10B981', // Emerald
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#8B5CF6', // Purple
    '#0EA5E9', // Sky
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.goalToEdit;
    _titleController = TextEditingController(text: g?.title ?? '');
    _descController = TextEditingController(text: g?.description ?? '');
    _selectedCategoryId = g?.categoryId;
    _targetDate = g?.targetDate;
    _selectedColor = g?.color ?? '#6366F1';
    _selectedStatus = g?.status ?? GoalStatus.inProgress;
  }

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
      initialDate: _targetDate ?? now.add(const Duration(days: 30)),
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

  void _addMilestonePrompt() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add Milestone',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Milestone Title',
                labelStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                hintText: 'e.g. Phase 1: DSA Foundations',
                hintStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF64748B) : AppColors.textSecondary.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Notes / Scope (Optional)',
                labelStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                hintText: 'e.g. Complete Easy & Medium arrays problems',
                hintStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF64748B) : AppColors.textSecondary.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _milestones.add({
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                    'order_index': _milestones.length + 1,
                  });
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: isDark ? theme.colorScheme.secondary : AppColors.primary),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);
    navigator.pop();

    final isEditing = widget.goalToEdit != null;
    final payload = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      'category_id': _selectedCategoryId,
      'target_date': _targetDate != null ? DateFormat('yyyy-MM-dd').format(_targetDate!) : null,
      'color': _selectedColor,
      'status': _selectedStatus.apiValue,
    };

    if (!isEditing && _milestones.isNotEmpty) {
      payload['milestones'] = _milestones;
    }

    final goalsNotifier = ref.read(goalsControllerProvider.notifier);
    if (isEditing) {
      await goalsNotifier.updateGoal(widget.goalToEdit!.id, payload);
    } else {
      await goalsNotifier.createGoal(payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tasksState = ref.watch(tasksControllerProvider);
    final goalsState = ref.watch(goalsControllerProvider);
    final isEditing = widget.goalToEdit != null;

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
        child: SingleChildScrollView(
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

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Goal' : 'Create Long-Term Goal',
                    style: GoogleFonts.inter(
                      fontSize: 17,
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

              // Title Field
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.inter(fontSize: 14.5, color: isDark ? Colors.white : AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Goal Title',
                  labelStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                  hintText: 'e.g. Master System Design 2026',
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
                    val == null || val.trim().isEmpty ? 'Please enter a goal title' : null,
              ),
              const SizedBox(height: 12),

              // Description Field
              TextFormField(
                controller: _descController,
                maxLines: 2,
                style: GoogleFonts.inter(fontSize: 13.5, color: isDark ? Colors.white : AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Description / Purpose (Optional)',
                  labelStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                  hintText: 'Why is this goal important to you?',
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
              const SizedBox(height: 14),

              // Category & Target Date Row
              Row(
                children: [
                  // Category Dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: GoogleFonts.inter(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                        prefixIcon: Icon(Icons.folder_outlined, size: 20, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        ...tasksState.categories.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name, overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Target Date Picker
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 18, color: isDark ? theme.colorScheme.secondary : AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _targetDate != null
                                    ? DateFormat('MMM d, yyyy').format(_targetDate!)
                                    : 'Target Date',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: _targetDate != null ? (isDark ? Colors.white : AppColors.textPrimary) : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Color Palette Picker
              Text(
                'Goal Theme Color',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: _colorPalette.map((hex) {
                  final colorVal = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                  final isSelected = _selectedColor.toUpperCase() == hex.toUpperCase();
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colorVal,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: isDark ? Colors.white : Colors.black87, width: 2.5) : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Initial Milestones (Only for create mode)
              if (!isEditing) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Roadmap Milestones (${_milestones.length})',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addMilestonePrompt,
                      icon: Icon(Icons.add_rounded, size: 16, color: isDark ? theme.colorScheme.secondary : AppColors.primary),
                      label: Text('Add Milestone', style: TextStyle(fontSize: 12, color: isDark ? theme.colorScheme.secondary : AppColors.primary)),
                    ),
                  ],
                ),
                if (_milestones.isNotEmpty)
                  Column(
                    children: _milestones.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final m = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${idx + 1}.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? theme.colorScheme.secondary : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                m['title'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                              onPressed: () => setState(() => _milestones.removeAt(idx)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: goalsState.isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? theme.colorScheme.secondary : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: goalsState.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isEditing ? 'Save Changes' : 'Create Goal',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
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
