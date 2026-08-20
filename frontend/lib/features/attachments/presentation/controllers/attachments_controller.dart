import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/attachments/data/attachments_repository.dart';
import 'package:frontend/features/attachments/domain/attachment_model.dart';
import 'package:frontend/features/goals/presentation/controllers/goals_controller.dart';
import 'package:frontend/features/tasks/presentation/controllers/tasks_controller.dart';

class EntityKey {
  final String? taskId;
  final String? goalId;
  final String? milestoneId;

  const EntityKey({this.taskId, this.goalId, this.milestoneId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityKey &&
          runtimeType == other.runtimeType &&
          taskId == other.taskId &&
          goalId == other.goalId &&
          milestoneId == other.milestoneId;

  @override
  int get hashCode => taskId.hashCode ^ goalId.hashCode ^ milestoneId.hashCode;
}

class AttachmentsState {
  final bool isLoading;
  final bool isUploading;
  final List<AttachmentModel> attachments;
  final String? errorMessage;
  final String selectedFilter; // ALL, IMAGE, DOCUMENT, LINK, NOTE
  final String? selectedTag;

  const AttachmentsState({
    this.isLoading = false,
    this.isUploading = false,
    this.attachments = const [],
    this.errorMessage,
    this.selectedFilter = 'ALL',
    this.selectedTag,
  });

  List<AttachmentModel> get filteredAttachments {
    var items = attachments;
    if (selectedFilter != 'ALL') {
      items = items.where((a) => a.type.toUpperCase() == selectedFilter).toList();
    }
    if (selectedTag != null && selectedTag!.isNotEmpty) {
      items = items.where((a) => a.tagsList.contains(selectedTag)).toList();
    }
    return items;
  }

  AttachmentsState copyWith({
    bool? isLoading,
    bool? isUploading,
    List<AttachmentModel>? attachments,
    String? errorMessage,
    String? selectedFilter,
    String? selectedTag,
    bool clearError = false,
    bool clearTag = false,
  }) {
    return AttachmentsState(
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      attachments: attachments ?? this.attachments,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedFilter: selectedFilter ?? this.selectedFilter,
      selectedTag: clearTag ? null : (selectedTag ?? this.selectedTag),
    );
  }
}

final attachmentsControllerProvider = StateNotifierProvider.family<
    AttachmentsController, AttachmentsState, EntityKey>((ref, key) {
  final repo = ref.watch(attachmentsRepositoryProvider);
  final tasksNotifier = ref.read(tasksControllerProvider.notifier);
  final goalsNotifier = ref.read(goalsControllerProvider.notifier);
  return AttachmentsController(repo, tasksNotifier, goalsNotifier, key);
});

class AttachmentsController extends StateNotifier<AttachmentsState> {
  final AttachmentsRepository _repository;
  final TasksController _tasksController;
  final GoalsController _goalsController;
  final EntityKey key;

  AttachmentsController(
    this._repository,
    this._tasksController,
    this._goalsController,
    this.key,
  ) : super(const AttachmentsState()) {
    loadAttachments();
  }

  Future<void> loadAttachments() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repository.listAttachments(
        taskId: key.taskId,
        goalId: key.goalId,
        milestoneId: key.milestoneId,
        tag: state.selectedTag,
      );
      state = state.copyWith(isLoading: false, attachments: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _extractError(e, 'Failed to load resources.'),
      );
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void setTag(String? tag) {
    if (tag == null) {
      state = state.copyWith(clearTag: true);
    } else {
      state = state.copyWith(selectedTag: tag);
    }
    loadAttachments();
  }

  Future<bool> uploadFile({
    required Uint8List fileBytes,
    required String filename,
    String? name,
    String? tags,
    bool isPinned = false,
  }) async {
    state = state.copyWith(isUploading: true, clearError: true);
    try {
      await _repository.uploadAttachment(
        fileBytes: fileBytes,
        filename: filename,
        taskId: key.taskId,
        goalId: key.goalId,
        milestoneId: key.milestoneId,
        name: name,
        tags: tags,
        isPinned: isPinned,
      );
      state = state.copyWith(isUploading: false);
      await loadAttachments();
      _notifyEntityChanged();
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: _extractError(e, 'Failed to upload attachment.'),
      );
      return false;
    }
  }

  Future<bool> addLink({
    required String name,
    required String url,
    String? tags,
    bool isPinned = false,
  }) async {
    state = state.copyWith(isUploading: true, clearError: true);
    try {
      await _repository.addLink(
        name: name,
        url: url,
        taskId: key.taskId,
        goalId: key.goalId,
        milestoneId: key.milestoneId,
        tags: tags,
        isPinned: isPinned,
      );
      state = state.copyWith(isUploading: false);
      await loadAttachments();
      _notifyEntityChanged();
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: _extractError(e, 'Failed to add link.'),
      );
      return false;
    }
  }

  Future<bool> addNote({
    required String name,
    required String content,
    String? tags,
    bool isPinned = false,
  }) async {
    state = state.copyWith(isUploading: true, clearError: true);
    try {
      await _repository.addNote(
        name: name,
        content: content,
        taskId: key.taskId,
        goalId: key.goalId,
        milestoneId: key.milestoneId,
        tags: tags,
        isPinned: isPinned,
      );
      state = state.copyWith(isUploading: false);
      await loadAttachments();
      _notifyEntityChanged();
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: _extractError(e, 'Failed to add note.'),
      );
      return false;
    }
  }

  Future<void> togglePin(String attachmentId) async {
    try {
      await _repository.togglePin(attachmentId);
      await loadAttachments();
    } catch (e) {
      state = state.copyWith(
        errorMessage: _extractError(e, 'Failed to update pin status.'),
      );
    }
  }

  Future<void> deleteAttachment(String attachmentId) async {
    try {
      await _repository.deleteAttachment(attachmentId);
      await loadAttachments();
      _notifyEntityChanged();
    } catch (e) {
      state = state.copyWith(
        errorMessage: _extractError(e, 'Failed to delete attachment.'),
      );
    }
  }

  void _notifyEntityChanged() {
    if (key.taskId != null) {
      _tasksController.loadData();
    }
    if (key.goalId != null) {
      _goalsController.loadGoals();
    }
  }

  String _extractError(dynamic error, String fallback) {
    if (error is DioException) {
      final res = error.response;
      if (res != null && res.data is Map && (res.data as Map).containsKey('detail')) {
        return res.data['detail'].toString();
      }
    }
    return fallback;
  }
}
