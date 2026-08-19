import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/review/data/review_api.dart';
import 'package:frontend/features/review/domain/review_model.dart';
import 'package:frontend/features/tasks/domain/task_model.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final api = ref.watch(reviewApiProvider);
  return ReviewRepository(api);
});

class ReviewRepository {
  final ReviewApi _api;

  ReviewRepository(this._api);

  Future<ReviewSummaryModel> getDailyReview({String? date}) async {
    return _api.getDailyReview(date: date);
  }

  Future<List<TaskModel>> batchReschedule(List<RescheduleItemModel> items) async {
    return _api.batchReschedule(items);
  }
}
