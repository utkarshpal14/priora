import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/planner/domain/planner_model.dart';
import 'package:frontend/features/planner/presentation/widgets/hourly_timeline_section.dart';
import 'package:frontend/features/tasks/domain/task_model.dart';

void main() {
  group('TaskSessionModel & Hourly Timeline Tests', () {
    test('TaskSessionModel accurately parses json and computes duration', () {
      final json = {
        'id': 'sess-1',
        'task_id': 't-1',
        'scheduled_start': '2026-08-20T10:00:00Z',
        'scheduled_end': '2026-08-20T12:00:00Z',
        'duration_minutes': 120,
        'formatted_time_range': '10:00 AM – 12:00 PM',
        'has_conflict': true,
        'conflicting_with': ['OS Lab'],
        'task': {
          'id': 't-1',
          'user_id': 'u-1',
          'title': 'Solve DSA Arrays',
          'priority': 'HIGH',
        },
      };

      final session = TaskSessionModel.fromJson(json);

      expect(session.id, equals('sess-1'));
      expect(session.taskId, equals('t-1'));
      expect(session.durationMinutes, equals(120));
      expect(session.formattedDuration, equals('2h'));
      expect(session.hasConflict, isTrue);
      expect(session.conflictingWith, contains('OS Lab'));
      expect(session.task?.title, equals('Solve DSA Arrays'));
    });

    testWidgets('HourlyTimelineSection renders scheduled time blocks and conflict badge',
        (WidgetTester tester) async {
      final session1 = TaskSessionModel(
        id: 'sess-1',
        taskId: 't-1',
        scheduledStart: DateTime(2026, 8, 20, 10, 0),
        scheduledEnd: DateTime(2026, 8, 20, 12, 0),
        durationMinutes: 120,
        formattedTimeRange: '10:00 AM – 12:00 PM',
        hasConflict: true,
        conflictingWith: const ['System Design'],
        task: const TaskModel(
          id: 't-1',
          userId: 'u-1',
          title: 'Solve DSA Arrays',
          priority: TaskPriority.high,
        ),
      );

      final session2 = TaskSessionModel(
        id: 'sess-2',
        taskId: 't-2',
        scheduledStart: DateTime(2026, 8, 20, 14, 0),
        scheduledEnd: DateTime(2026, 8, 20, 15, 30),
        durationMinutes: 90,
        formattedTimeRange: '2:00 PM – 3:30 PM',
        hasConflict: false,
        task: const TaskModel(
          id: 't-2',
          userId: 'u-1',
          title: 'College Lab Work',
          priority: TaskPriority.medium,
        ),
      );

      final unscheduled = [
        const TaskModel(
          id: 't-3',
          userId: 'u-1',
          title: 'Renew Library Book',
          priority: TaskPriority.low,
        ),
      ];

      String? deletedSessionId;
      TaskModel? completedTask;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HourlyTimelineSection(
                timeBlocks: [session1, session2],
                unscheduledTasks: unscheduled,
                isViewingToday: true,
                selectedDate: DateTime(2026, 8, 20),
                onDeleteSession: (id) => deletedSessionId = id,
                onToggleTaskComplete: (t) => completedTask = t,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify Header
      expect(find.text('Hourly Schedule'), findsOneWidget);
      expect(find.text('2 focus blocks'), findsOneWidget);

      // Verify Current Time Marker (when viewing today)
      expect(find.textContaining('NOW'), findsOneWidget);

      // Verify Session 1
      expect(find.text('Solve DSA Arrays'), findsOneWidget);
      expect(find.text('2h'), findsOneWidget);
      expect(find.text('Overlap: System Design'), findsOneWidget);

      // Verify Session 2
      expect(find.text('College Lab Work'), findsOneWidget);
      expect(find.text('1h 30m'), findsOneWidget);

      // Verify Unscheduled Section
      expect(find.text('Ready to Schedule (1)'), findsOneWidget);
      expect(find.text('Renew Library Book'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
    });
  });
}
