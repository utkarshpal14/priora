import 'category_model.dart';
import 'task_model.dart';

enum TaskTabFilter {
  pending,
  completed,
  all,
}

class TaskMetricsModel {
  final int total;
  final int completed;
  final int pending;

  const TaskMetricsModel({
    this.total = 0,
    this.completed = 0,
    this.pending = 0,
  });

  factory TaskMetricsModel.fromJson(Map<String, dynamic> json) {
    return TaskMetricsModel(
      total: (json['total'] ?? 0) as int,
      completed: (json['completed'] ?? 0) as int,
      pending: (json['pending'] ?? 0) as int,
    );
  }
}

class TasksState {
  final List<TaskModel> tasks;
  final List<CategoryModel> categories;
  final TaskMetricsModel metrics;
  final TaskTabFilter tabFilter;
  final TaskPriority? priorityFilter;
  final String? categoryFilterId;
  final String searchQuery;
  final bool isLoading;
  final bool isCreating;
  final String? errorMessage;

  const TasksState({
    this.tasks = const [],
    this.categories = const [],
    this.metrics = const TaskMetricsModel(),
    this.tabFilter = TaskTabFilter.pending,
    this.priorityFilter,
    this.categoryFilterId,
    this.searchQuery = '',
    this.isLoading = false,
    this.isCreating = false,
    this.errorMessage,
  });

  List<TaskModel> get filteredTasks {
    return tasks.where((task) {
      // Tab status filter
      if (tabFilter == TaskTabFilter.pending && task.isCompleted) return false;
      if (tabFilter == TaskTabFilter.completed && !task.isCompleted) return false;

      // Priority filter
      if (priorityFilter != null && task.priority != priorityFilter) return false;

      // Category filter
      if (categoryFilterId != null && task.categoryId != categoryFilterId) return false;

      // Search query
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchTitle = task.title.toLowerCase().contains(query);
        final matchDesc = task.description?.toLowerCase().contains(query) ?? false;
        if (!matchTitle && !matchDesc) return false;
      }

      return true;
    }).toList();
  }

  TasksState copyWith({
    List<TaskModel>? tasks,
    List<CategoryModel>? categories,
    TaskMetricsModel? metrics,
    TaskTabFilter? tabFilter,
    TaskPriority? priorityFilter,
    bool clearPriorityFilter = false,
    String? categoryFilterId,
    bool clearCategoryFilter = false,
    String? searchQuery,
    bool? isLoading,
    bool? isCreating,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      categories: categories ?? this.categories,
      metrics: metrics ?? this.metrics,
      tabFilter: tabFilter ?? this.tabFilter,
      priorityFilter: clearPriorityFilter ? null : (priorityFilter ?? this.priorityFilter),
      categoryFilterId: clearCategoryFilter ? null : (categoryFilterId ?? this.categoryFilterId),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
