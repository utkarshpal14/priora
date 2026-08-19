import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/review/domain/review_model.dart';
import 'package:frontend/features/review/presentation/widgets/evening_review_banner.dart';
import 'package:frontend/features/review/presentation/widgets/review_celebration_dialog.dart';
import 'package:frontend/features/review/presentation/widgets/review_task_action_card.dart';
import 'package:frontend/features/tasks/domain/task_model.dart';

void main() {
  test('ReviewSummaryModel formats duration and parses json accurately', () {
    const summary1 = ReviewSummaryModel(
      date: '2026-08-20',
      totalCompletedMinutes: 90,
    );
    expect(summary1.formattedCompletedDuration, equals('1h 30m'));

    const summary2 = ReviewSummaryModel(
      date: '2026-08-20',
      totalCompletedMinutes: 45,
    );
    expect(summary2.formattedCompletedDuration, equals('45m'));

    final jsonMap = {
      'date': '2026-08-20',
      'completed_count': 3,
      'incomplete_count': 2,
      'overdue_count': 1,
      'completion_rate': 60.0,
      'total_completed_minutes': 120,
      'completed_tasks': [],
      'incomplete_tasks': [],
    };
    final parsed = ReviewSummaryModel.fromJson(jsonMap);
    expect(parsed.completedCount, equals(3));
    expect(parsed.incompleteCount, equals(2));
    expect(parsed.overdueCount, equals(1));
    expect(parsed.completionRate, equals(60.0));
    expect(parsed.formattedCompletedDuration, equals('2h'));
  });

  testWidgets('ReviewTaskActionCard renders action chips and invokes callbacks',
      (WidgetTester tester) async {
    const task = TaskModel(
      id: 'task-101',
      userId: 'user-1',
      title: 'Complete Distributed Algorithms Lab',
      priority: TaskPriority.critical,
      estimatedMinutes: 60,
    );

    RescheduleAction? selectedAction;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReviewTaskActionCard(
            task: task,
            stagedAction: null,
            onSelectAction: (action, {customDeadline}) {
              selectedAction = action;
            },
            onClearAction: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Complete Distributed Algorithms Lab'), findsOneWidget);
    expect(find.text('CRITICAL'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('Next Week'), findsOneWidget);
    expect(find.text('Pick Date'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap Tomorrow
    await tester.tap(find.text('Tomorrow'));
    expect(selectedAction, equals(RescheduleAction.moveTomorrow));

    // Tap Next Week
    await tester.tap(find.text('Next Week'));
    expect(selectedAction, equals(RescheduleAction.moveNextWeek));

    // Tap Done
    await tester.tap(find.text('Done'));
    expect(selectedAction, equals(RescheduleAction.complete));
  });

  testWidgets('EveningReviewBanner renders title and task count', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EveningReviewBanner(incompleteCount: 3),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('End-of-Day Review'), findsOneWidget);
    expect(find.text('3 tasks to wrap up or reschedule'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
  });

  testWidgets('ReviewCelebrationDialog displays stats recap', (WidgetTester tester) async {
    const summary = ReviewSummaryModel(
      date: '2026-08-20',
      completedCount: 5,
      totalCompletedMinutes: 150, // 2h 30m
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReviewCelebrationDialog(
            summary: summary,
            rescheduledCount: 2,
            onDismiss: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Day Wrapped Up!'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Rescheduled'), findsOneWidget);
    expect(find.text('2h 30m'), findsOneWidget);
    expect(find.text('Back to Planner'), findsOneWidget);
  });
}
