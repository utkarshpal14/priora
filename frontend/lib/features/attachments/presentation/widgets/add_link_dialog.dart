import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddLinkDialog extends StatefulWidget {
  final Function({
    required String name,
    required String url,
    String? tags,
    bool isPinned,
  }) onSubmit;

  const AddLinkDialog({super.key, required this.onSubmit});

  static Future<void> show(
    BuildContext context, {
    required Function({
      required String name,
      required String url,
      String? tags,
      bool isPinned,
    }) onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AddLinkDialog(onSubmit: onSubmit),
    );
  }

  @override
  State<AddLinkDialog> createState() => _AddLinkDialogState();
}

class _AddLinkDialogState extends State<AddLinkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isPinned = false;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        name: _nameController.text.trim(),
        url: _urlController.text.trim(),
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
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.link_rounded, color: Color(0xFF0284C7), size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'Attach Web Link',
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
                  labelText: 'Title / Resource Name *',
                  hintText: 'e.g. Striver A2Z Sheet, Notion Doc',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'URL *',
                  hintText: 'https://github.com/... or https://notion.so/...',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'URL is required';
                  final trimmed = val.trim();
                  if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
                    return 'URL must start with http:// or https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (Optional)',
                  hintText: 'e.g. DSA, Placement, Arrays',
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
          label: const Text('Attach Link'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
