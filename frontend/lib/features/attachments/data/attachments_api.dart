import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/attachments/domain/attachment_model.dart';

final attachmentsApiProvider = Provider<AttachmentsApi>((ref) {
  final dio = ref.watch(dioProvider);
  return AttachmentsApi(dio);
});

class AttachmentsApi {
  final Dio _dio;

  AttachmentsApi(this._dio);

  Future<AttachmentModel> uploadAttachment({
    required Uint8List fileBytes,
    required String filename,
    String? taskId,
    String? goalId,
    String? milestoneId,
    String? name,
    String? tags,
    bool isPinned = false,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: filename),
      if (taskId != null) 'task_id': taskId,
      if (goalId != null) 'goal_id': goalId,
      if (milestoneId != null) 'milestone_id': milestoneId,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (tags != null && tags.trim().isNotEmpty) 'tags': tags.trim(),
      'is_pinned': isPinned,
    });

    final response = await _dio.post(
      '${ApiEndpoints.attachments}/upload',
      data: formData,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return AttachmentModel.fromJson(data);
  }

  Future<AttachmentModel> addLink({
    required String name,
    required String url,
    String? taskId,
    String? goalId,
    String? milestoneId,
    String? tags,
    bool isPinned = false,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'url': url.trim(),
      if (taskId != null) 'task_id': taskId,
      if (goalId != null) 'goal_id': goalId,
      if (milestoneId != null) 'milestone_id': milestoneId,
      if (tags != null && tags.trim().isNotEmpty) 'tags': tags.trim(),
      'is_pinned': isPinned,
    };

    final response = await _dio.post(
      '${ApiEndpoints.attachments}/link',
      data: payload,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return AttachmentModel.fromJson(data);
  }

  Future<AttachmentModel> addNote({
    required String name,
    required String content,
    String? taskId,
    String? goalId,
    String? milestoneId,
    String? tags,
    bool isPinned = false,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'content': content.trim(),
      if (taskId != null) 'task_id': taskId,
      if (goalId != null) 'goal_id': goalId,
      if (milestoneId != null) 'milestone_id': milestoneId,
      if (tags != null && tags.trim().isNotEmpty) 'tags': tags.trim(),
      'is_pinned': isPinned,
    };

    final response = await _dio.post(
      '${ApiEndpoints.attachments}/note',
      data: payload,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return AttachmentModel.fromJson(data);
  }

  Future<List<AttachmentModel>> listAttachments({
    String? taskId,
    String? goalId,
    String? milestoneId,
    String? tag,
  }) async {
    final queryParams = <String, dynamic>{
      if (taskId != null) 'task_id': taskId,
      if (goalId != null) 'goal_id': goalId,
      if (milestoneId != null) 'milestone_id': milestoneId,
      if (tag != null && tag.trim().isNotEmpty) 'tag': tag.trim(),
    };

    final response = await _dio.get(
      ApiEndpoints.attachments,
      queryParameters: queryParams,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final list = data['attachments'] as List<dynamic>? ?? [];
    return list.map((item) => AttachmentModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<AttachmentModel>> searchAttachments(
    String query, {
    String? tag,
    String? type,
  }) async {
    final queryParams = <String, dynamic>{
      'q': query.trim(),
      if (tag != null && tag.trim().isNotEmpty) 'tag': tag.trim(),
      if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
    };

    final response = await _dio.get(
      '${ApiEndpoints.attachments}/search',
      queryParameters: queryParams,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final list = data['attachments'] as List<dynamic>? ?? [];
    return list.map((item) => AttachmentModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<AttachmentModel> togglePin(String attachmentId) async {
    final response = await _dio.patch(
      '${ApiEndpoints.attachments}/$attachmentId/pin',
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return AttachmentModel.fromJson(data);
  }

  Future<void> deleteAttachment(String attachmentId) async {
    await _dio.delete(
      '${ApiEndpoints.attachments}/$attachmentId',
    );
  }
}
