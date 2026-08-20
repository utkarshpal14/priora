import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/attachments/data/attachments_api.dart';
import 'package:frontend/features/attachments/domain/attachment_model.dart';

final attachmentsRepositoryProvider = Provider<AttachmentsRepository>((ref) {
  final api = ref.watch(attachmentsApiProvider);
  return AttachmentsRepository(api);
});

class AttachmentsRepository {
  final AttachmentsApi _api;

  AttachmentsRepository(this._api);

  Future<AttachmentModel> uploadAttachment({
    required Uint8List fileBytes,
    required String filename,
    String? taskId,
    String? goalId,
    String? milestoneId,
    String? name,
    String? tags,
    bool isPinned = false,
  }) {
    return _api.uploadAttachment(
      fileBytes: fileBytes,
      filename: filename,
      taskId: taskId,
      goalId: goalId,
      milestoneId: milestoneId,
      name: name,
      tags: tags,
      isPinned: isPinned,
    );
  }

  Future<AttachmentModel> addLink({
    required String name,
    required String url,
    String? taskId,
    String? goalId,
    String? milestoneId,
    String? tags,
    bool isPinned = false,
  }) {
    return _api.addLink(
      name: name,
      url: url,
      taskId: taskId,
      goalId: goalId,
      milestoneId: milestoneId,
      tags: tags,
      isPinned: isPinned,
    );
  }

  Future<AttachmentModel> addNote({
    required String name,
    required String content,
    String? taskId,
    String? goalId,
    String? milestoneId,
    String? tags,
    bool isPinned = false,
  }) {
    return _api.addNote(
      name: name,
      content: content,
      taskId: taskId,
      goalId: goalId,
      milestoneId: milestoneId,
      tags: tags,
      isPinned: isPinned,
    );
  }

  Future<List<AttachmentModel>> listAttachments({
    String? taskId,
    String? goalId,
    String? milestoneId,
    String? tag,
  }) {
    return _api.listAttachments(
      taskId: taskId,
      goalId: goalId,
      milestoneId: milestoneId,
      tag: tag,
    );
  }

  Future<List<AttachmentModel>> searchAttachments(
    String query, {
    String? tag,
    String? type,
  }) {
    return _api.searchAttachments(query, tag: tag, type: type);
  }

  Future<AttachmentModel> togglePin(String attachmentId) {
    return _api.togglePin(attachmentId);
  }

  Future<void> deleteAttachment(String attachmentId) {
    return _api.deleteAttachment(attachmentId);
  }
}
