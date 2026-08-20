import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddNoteDialog extends StatefulWidget {
  final Function({
    required String name,
    required String content,
    String? tags,
    bool isPinned,
  }) onSubmit;

  const AddNoteDialog({super.key, required this.onSubmit});

  static Future<void> show(
    BuildContext context, {
    required Function({
      required String name,
      required String content,
      String? tags,
      bool isPinned,
    }) onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AddNoteDialog(onSubmit: onSubmit),
    );
  }

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isPinned = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        name: _nameController.text.trim(),
        content: _contentController.text.trim(),
        tags: _tagsController.text.trim().isEmpty ? null : _tagsController.text.trim(),
        isPinned: _isPinned,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notes_rounded, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'Add Quick Revision Note',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Note Title *',
                  hintText: 'e.g. OS Deadlock Formulas, Kadane Checklist',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Content / Snippet (Markdown supported) *',
                  hintText: '- Revise B-trees indexing\n- Review TCP 3-way handshake',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Note content is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (Optional)',
                  hintText: 'e.g. OS, Interview, Formulas',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Pin to top',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                value: _isPinned,
                onChanged: (val) => setState(() => _isPinned = val ?? false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Save Note'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
