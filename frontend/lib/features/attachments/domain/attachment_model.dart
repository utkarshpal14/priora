import 'package:flutter/material.dart';
import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/features/tasks/domain/task_model.dart';

class AttachmentModel {
  final String id;
  final String userId;
  final String? taskId;
  final String? goalId;
  final String? milestoneId;
  final String type; // IMAGE, DOCUMENT, LINK, NOTE
  final String sourceType; // UPLOAD, LINK, NOTE
  final String name;
  final String? originalFilename;
  final String? url;
  final String? thumbnailUrl;
  final String? domain;
  final String? siteName;
  final String? faviconUrl;
  final String? content;
  final String? tags;
  final String? fileHash;
  final String? mimeType;
  final int? fileSizeBytes;
  final bool isPinned;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AttachmentModel({
    required this.id,
    required this.userId,
    this.taskId,
    this.goalId,
    this.milestoneId,
    required this.type,
    this.sourceType = 'UPLOAD',
    required this.name,
    this.originalFilename,
    this.url,
    this.thumbnailUrl,
    this.domain,
    this.siteName,
    this.faviconUrl,
    this.content,
    this.tags,
    this.fileHash,
    this.mimeType,
    this.fileSizeBytes,
    this.isPinned = false,
    this.createdAt,
    this.updatedAt,
  });

  bool get isImage => type.toUpperCase() == 'IMAGE';
  bool get isDocument => type.toUpperCase() == 'DOCUMENT';
  bool get isLink => type.toUpperCase() == 'LINK';
  bool get isNote => type.toUpperCase() == 'NOTE';

  List<String> get tagsList {
    if (tags == null || tags!.trim().isEmpty) return const [];
    return tags!.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  }

  String? get formattedSize {
    if (fileSizeBytes == null) return null;
    final bytes = fileSizeBytes!;
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Full absolute preview/download URL resolved against baseUrl
  String? get fullUrl {
    if (url == null) return null;
    if (url!.startsWith('http://') || url!.startsWith('https://')) {
      return url;
    }
    final cleanBase = ApiEndpoints.baseUrl.replaceAll('/api/v1', '');
    return '$cleanBase${url!.startsWith('/') ? '' : '/'}$url';
  }

  String? get fullThumbnailUrl {
    if (thumbnailUrl == null) return fullUrl;
    if (thumbnailUrl!.startsWith('http://') || thumbnailUrl!.startsWith('https://')) {
      return thumbnailUrl;
    }
    final cleanBase = ApiEndpoints.baseUrl.replaceAll('/api/v1', '');
    return '$cleanBase${thumbnailUrl!.startsWith('/') ? '' : '/'}$thumbnailUrl';
  }

  IconData get icon {
    if (isImage) return Icons.image_rounded;
    if (isDocument) {
      final ext = (originalFilename ?? name).toLowerCase();
      if (ext.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
      if (ext.endsWith('.doc') || ext.endsWith('.docx')) return Icons.description_rounded;
      return Icons.insert_drive_file_rounded;
    }
    if (isLink) return Icons.link_rounded;
    return Icons.notes_rounded;
  }

  Color get color {
    if (isImage) return const Color(0xFF6366F1); // Indigo
    if (isDocument) return const Color(0xFFEA580C); // Orange
    if (isLink) return const Color(0xFF0284C7); // Sky Blue
    return const Color(0xFF10B981); // Emerald Green
  }

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      taskId: json['task_id'] as String?,
      goalId: json['goal_id'] as String?,
      milestoneId: json['milestone_id'] as String?,
      type: (json['type'] as String?) ?? 'DOCUMENT',
      sourceType: (json['source_type'] as String?) ?? 'UPLOAD',
      name: (json['name'] as String?) ?? '',
      originalFilename: json['original_filename'] as String?,
      url: json['url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      domain: json['domain'] as String?,
      siteName: json['site_name'] as String?,
      faviconUrl: json['favicon_url'] as String?,
      content: json['content'] as String?,
      tags: json['tags'] as String?,
      fileHash: json['file_hash'] as String?,
      mimeType: json['mime_type'] as String?,
      fileSizeBytes: json['file_size_bytes'] as int?,
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: json['created_at'] != null ? TaskModel.parseUtcDateTime(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? TaskModel.parseUtcDateTime(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'task_id': taskId,
      'goal_id': goalId,
      'milestone_id': milestoneId,
      'type': type,
      'source_type': sourceType,
      'name': name,
      'original_filename': originalFilename,
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'domain': domain,
      'site_name': siteName,
      'favicon_url': faviconUrl,
      'content': content,
      'tags': tags,
      'file_hash': fileHash,
      'mime_type': mimeType,
      'file_size_bytes': fileSizeBytes,
      'is_pinned': isPinned,
    };
  }

  AttachmentModel copyWith({
    String? id,
    String? userId,
    String? taskId,
    String? goalId,
    String? milestoneId,
    String? type,
    String? sourceType,
    String? name,
    String? originalFilename,
    String? url,
    String? thumbnailUrl,
    String? domain,
    String? siteName,
    String? faviconUrl,
    String? content,
    String? tags,
    String? fileHash,
    String? mimeType,
    int? fileSizeBytes,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttachmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskId: taskId ?? this.taskId,
      goalId: goalId ?? this.goalId,
      milestoneId: milestoneId ?? this.milestoneId,
      type: type ?? this.type,
      sourceType: sourceType ?? this.sourceType,
      name: name ?? this.name,
      originalFilename: originalFilename ?? this.originalFilename,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      domain: domain ?? this.domain,
      siteName: siteName ?? this.siteName,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      fileHash: fileHash ?? this.fileHash,
      mimeType: mimeType ?? this.mimeType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
