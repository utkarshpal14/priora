import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/goals/domain/goal_model.dart';
import 'package:frontend/features/goals/presentation/widgets/goal_card.dart';
import 'package:frontend/features/tasks/domain/task_model.dart';

void main() {
  test('GoalModel accurately parses json and computes metrics', () {
    final jsonMap = {
      'id': 'goal-101',
      'user_id': 'user-1',
      'title': 'Master System Design',
      'description': 'Distributed caching, load balancing, sharding.',
      'target_date': '2026-12-31',
      'status': 'IN_PROGRESS',
      'color': '#10B981',
      'progress_percentage': 50.0,
      'milestones_count': 2,
      'completed_milestones_count': 1,
      'tasks_count': 2,
      'completed_tasks_count': 1,
      'milestones': [
        {
          'id': 'ms-1',
          'goal_id': 'goal-101',
          'title': 'Read DDIA Book',
          'description': 'Storage engines & consensus',
          'is_completed': true,
          'order_index': 1,
        }
      ],
      'tasks': [],
      'recent_activity': [
        {
          'id': 'milestone-ms-1',
          'type': 'MILESTONE',
          'title': 'Read DDIA Book',
          'completed_at': '2026-08-19T10:00:00Z',
        }
      ],
    };

    final goal = GoalModel.fromJson(jsonMap);

    expect(goal.title, equals('Master System Design'));
    expect(goal.status, equals(GoalStatus.inProgress));
    expect(goal.progressPercentage, equals(50.0));
    expect(goal.milestones.length, equals(1));
    expect(goal.milestones[0].title, equals('Read DDIA Book'));
    expect(goal.milestones[0].isCompleted, isTrue);
    expect(goal.recentActivity.length, equals(1));
    expect(goal.recentActivity[0].type, equals('MILESTONE'));
    expect(goal.displayColor, equals(const Color(0xFF10B981)));
    expect(goal.formattedTargetDate, equals('Dec 31, 2026'));
  });

  test('GoalActivityItem formats relative time properly', () {
    final now = DateTime.now();
    final itemJustNow = GoalActivityItem(
      id: 'act-1',
      type: 'TASK',
      title: 'Complete Two Sum',
      completedAt: now.subtract(const Duration(minutes: 2)),
    );
    expect(itemJustNow.timeAgo, equals('2m ago'));

    final itemHoursAgo = GoalActivityItem(
      id: 'act-2',
      type: 'MILESTONE',
      title: 'Finish Arrays',
      completedAt: now.subtract(const Duration(hours: 3)),
    );
    expect(itemHoursAgo.timeAgo, equals('3h ago'));

    final itemDaysAgo = GoalActivityItem(
      id: 'act-3',
      type: 'TASK',
      title: 'Implement LRU Cache',
      completedAt: now.subtract(const Duration(days: 4)),
    );
    expect(itemDaysAgo.timeAgo, equals('4d ago'));
  });

  testWidgets('GoalCard renders goal details and responds to tap', (WidgetTester tester) async {
    const goal = GoalModel(
      id: 'goal-202',
      userId: 'user-1',
      title: 'Placement 2026 Roadmap',
      description: 'Prepare DSA and system design for interviews.',
      status: GoalStatus.inProgress,
      color: '#6366F1',
      progressPercentage: 75.0,
      milestonesCount: 4,
      completedMilestonesCount: 3,
      tasksCount: 4,
      completedTasksCount: 3,
    );

    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoalCard(
            goal: goal,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Placement 2026 Roadmap'), findsOneWidget);
    expect(find.text('Prepare DSA and system design for interviews.'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('3/4'), findsNWidgets(2)); // Milestones and Tasks
    expect(find.text('In Progress'), findsOneWidget);

    await tester.tap(find.text('Placement 2026 Roadmap'));
    expect(tapped, isTrue);
  });
}
