import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/features/attachments/domain/attachment_model.dart';
import 'package:frontend/features/attachments/presentation/controllers/attachments_controller.dart';
import 'package:frontend/features/attachments/presentation/widgets/add_link_dialog.dart';
import 'package:frontend/features/attachments/presentation/widgets/add_note_dialog.dart';
import 'package:frontend/features/attachments/presentation/widgets/attachment_preview_dialog.dart';

class ResourceSectionWidget extends ConsumerWidget {
  final String? taskId;
  final String? goalId;
  final String? milestoneId;
  final bool compactMode;

  const ResourceSectionWidget({
    super.key,
    this.taskId,
    this.goalId,
    this.milestoneId,
    this.compactMode = false,
  });

  EntityKey get _key => EntityKey(taskId: taskId, goalId: goalId, milestoneId: milestoneId);

  Future<void> _pickAndUploadFile(BuildContext context, WidgetRef ref, {bool imagesOnly = false}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: imagesOnly ? FileType.image : FileType.any,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        final bytes = pickedFile.bytes;
        if (bytes == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not read file bytes.')),
            );
          }
          return;
        }

        final filename = pickedFile.name;
        final controller = ref.read(attachmentsControllerProvider(_key).notifier);

        final success = await controller.uploadFile(
          fileBytes: bytes,
          filename: filename,
        );

        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Uploaded "$filename" successfully!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  void _showAddLinkDialog(BuildContext context, WidgetRef ref) {
    AddLinkDialog.show(
      context,
      onSubmit: ({required name, required url, tags, isPinned = false}) {
        ref.read(attachmentsControllerProvider(_key).notifier).addLink(
              name: name,
              url: url,
              tags: tags,
              isPinned: isPinned,
            );
      },
    );
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    AddNoteDialog.show(
      context,
      onSubmit: ({required name, required content, tags, isPinned = false}) {
        ref.read(attachmentsControllerProvider(_key).notifier).addNote(
              name: name,
              content: content,
              tags: tags,
              isPinned: isPinned,
            );
      },
    );
  }

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String label, String filterKey, AttachmentsState state) {
    final isSelected = state.selectedFilter == filterKey;
    return GestureDetector(
      onTap: () => ref.read(attachmentsControllerProvider(_key).notifier).setFilter(filterKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildResourceCard(BuildContext context, WidgetRef ref, AttachmentModel att) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: att.isPinned ? const Color(0xFF6366F1).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          width: att.isPinned ? 1.5 : 1.0,
        ),
        boxShadow: att.isPinned
            ? [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
            : null,
      ),
      child: Row(
        children: [
          // Visual Icon / Thumbnail
          GestureDetector(
            onTap: () {
              if (att.isImage) {
                AttachmentPreviewDialog.showImagePreview(context, att);
              } else if (att.isNote) {
                AttachmentPreviewDialog.showNotePreview(context, att);
              } else if (att.isLink || att.isDocument) {
                AttachmentPreviewDialog.launchUrlResource(context, att);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: att.isImage && att.fullThumbnailUrl != null
                  ? Image.network(
                      att.fullThumbnailUrl!,
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, _, __) => Container(
                        width: 42,
                        height: 42,
                        color: att.color.withValues(alpha: 0.1),
                        child: Icon(att.icon, color: att.color, size: 20),
                      ),
                    )
                  : Container(
                      width: 42,
                      height: 42,
                      color: att.color.withValues(alpha: 0.1),
                      child: Icon(att.icon, color: att.color, size: 20),
                    ),
            ),
          ),
          const SizedBox(width: 10),

          // Title & Metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (att.isPinned)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.push_pin_rounded, color: Color(0xFF6366F1), size: 13),
                      ),
                    Expanded(
                      child: Text(
                        att.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (att.isLink && att.domain != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          att.siteName ?? att.domain!,
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF0284C7)),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (att.formattedSize != null)
                      Text(
                        att.formattedSize!,
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                    if (att.isNote)
                      Text(
                        'Quick Note',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF10B981), fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
                if (att.tagsList.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: att.tagsList
                        .take(3)
                        .map((t) => Text(
                              '#$t',
                              style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),

          // Actions
          IconButton(
            onPressed: () {
              if (att.isImage) {
                AttachmentPreviewDialog.showImagePreview(context, att);
              } else if (att.isNote) {
                AttachmentPreviewDialog.showNotePreview(context, att);
              } else {
                AttachmentPreviewDialog.launchUrlResource(context, att);
              }
            },
            icon: Icon(att.isImage ? Icons.visibility_rounded : Icons.open_in_new_rounded, size: 18, color: const Color(0xFF64748B)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'View Resource',
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            iconSize: 18,
            onSelected: (val) {
              if (val == 'pin') {
                ref.read(attachmentsControllerProvider(_key).notifier).togglePin(att.id);
              } else if (val == 'delete') {
                ref.read(attachmentsControllerProvider(_key).notifier).deleteAttachment(att.id);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'pin',
                child: Row(
                  children: [
                    Icon(att.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded, size: 16),
                    const SizedBox(width: 8),
                    Text(att.isPinned ? 'Unpin Resource' : 'Pin to Top', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(fontSize: 13, color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attachmentsControllerProvider(_key));
    final filtered = state.filteredAttachments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file_rounded, size: 18, color: Color(0xFF6366F1)),
                const SizedBox(width: 6),
                Text(
                  'Resources & Attachments',
                  style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                ),
                if (state.attachments.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${state.attachments.length}',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF6366F1)),
                    ),
                  ),
                ],
              ],
            ),
            if (state.isUploading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Quick Add Action Buttons Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickAndUploadFile(context, ref, imagesOnly: true),
                icon: const Icon(Icons.photo_library_rounded, size: 14),
                label: const Text('Photo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: () => _pickAndUploadFile(context, ref, imagesOnly: false),
                icon: const Icon(Icons.upload_file_rounded, size: 14),
                label: const Text('File'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: () => _showAddLinkDialog(context, ref),
                icon: const Icon(Icons.link_rounded, size: 14),
                label: const Text('Web Link'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: () => _showAddNoteDialog(context, ref),
                icon: const Icon(Icons.edit_note_rounded, size: 14),
                label: const Text('Note'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Filter chips bar
        if (state.attachments.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(context, ref, 'All (${state.attachments.length})', 'ALL', state),
                const SizedBox(width: 4),
                _buildFilterChip(context, ref, 'Images', 'IMAGE', state),
                const SizedBox(width: 4),
                _buildFilterChip(context, ref, 'Files', 'DOCUMENT', state),
                const SizedBox(width: 4),
                _buildFilterChip(context, ref, 'Links', 'LINK', state),
                const SizedBox(width: 4),
                _buildFilterChip(context, ref, 'Notes', 'NOTE', state),
              ],
            ),
          ),
        const SizedBox(height: 10),

        // List of resources
        if (state.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Text(
                state.attachments.isEmpty
                    ? 'No resources attached yet. Tap above to add photos, documents, links, or notes.'
                    : 'No items match the selected filter.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              ),
            ),
          )
        else
          ...filtered.map((att) => _buildResourceCard(context, ref, att)),
      ],
    );
  }
}
