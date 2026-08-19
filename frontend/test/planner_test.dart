import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/planner/domain/planner_model.dart';
import 'package:frontend/features/planner/presentation/widgets/calendar_strip.dart';
import 'package:frontend/features/planner/presentation/widgets/planner_progress_summary.dart';
import 'package:frontend/features/planner/presentation/widgets/smart_focus_section.dart';
import 'package:frontend/features/planner/presentation/widgets/timeline_schedule_section.dart';
import 'package:frontend/features/planner/presentation/widgets/weekly_preview_section.dart';
import 'package:frontend/features/tasks/domain/task_model.dart';

void main() {
  test('DayPlanSummaryModel formattedTotalDuration formats minutes correctly', () {
    const summary1 = DayPlanSummaryModel(totalEstimatedMinutes: 45);
    expect(summary1.formattedTotalDuration, equals('45m'));

    const summary2 = DayPlanSummaryModel(totalEstimatedMinutes: 120);
    expect(summary2.formattedTotalDuration, equals('2h'));

    const summary3 = DayPlanSummaryModel(totalEstimatedMinutes: 135);
    expect(summary3.formattedTotalDuration, equals('2h 15m'));

    const summary4 = DayPlanSummaryModel(totalEstimatedMinutes: 0);
    expect(summary4.formattedTotalDuration, equals('0m'));
  });

  testWidgets('PlannerProgressSummary renders completion percentage and workload duration',
      (WidgetTester tester) async {
    const summary = DayPlanSummaryModel(
      total: 5,
      completed: 2,
      pending: 3,
      overdueCount: 1,
      completionPercentage: 40.0,
      totalEstimatedMinutes: 105, // 1h 45m
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlannerProgressSummary(
            summary: summary,
            isViewingToday: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text("Today's Progress"), findsOneWidget);
    expect(find.text('2 of 5 tasks completed'), findsOneWidget);
    expect(find.text('3 pending'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('1h 45m'), findsOneWidget);
  });

  testWidgets('SmartFocusSection renders top priority tasks with actionable buttons',
      (WidgetTester tester) async {
    final focusTasks = [
      const TaskModel(
        id: 'f-1',
        userId: 'u-1',
        title: 'Complete Distributed Systems Lab',
        priority: TaskPriority.critical,
        estimatedMinutes: 90,
      ),
      const TaskModel(
        id: 'f-2',
        userId: 'u-1',
        title: 'Review Algorithms Sheet',
        priority: TaskPriority.high,
        estimatedMinutes: 45,
      ),
    ];

    TaskModel? startedTask;
    TaskModel? completedTask;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartFocusSection(
            focusTasks: focusTasks,
            onStartTask: (t) => startedTask = t,
            onToggleComplete: (t) => completedTask = t,
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify Focus header and items
    expect(find.text('Top Focus'), findsOneWidget);
    expect(find.text('2 PRIORITIES'), findsOneWidget);
    expect(find.text('Complete Distributed Systems Lab'), findsOneWidget);
    expect(find.text('Review Algorithms Sheet'), findsOneWidget);
    expect(find.text('CRITICAL'), findsOneWidget);
    expect(find.text('HIGH'), findsOneWidget);
    expect(find.text('1h 30m'), findsOneWidget);
    expect(find.text('45m'), findsOneWidget);

    // Tap Start on first task
    await tester.tap(find.text('Start').first);
    expect(startedTask?.id, equals('f-1'));

    // Tap Done on second task
    await tester.tap(find.text('Done').last);
    expect(completedTask?.id, equals('f-2'));
  });

  testWidgets('TimelineScheduleSection renders buckets and tasks', (WidgetTester tester) async {
    final buckets = [
      const TimelineBucketModel(
        name: 'Morning',
        timeRange: 'Before 12:00 PM',
        tasks: [
          TaskModel(
            id: 't-m1',
            userId: 'u-1',
            title: 'Morning Daily Scrum',
            priority: TaskPriority.high,
            estimatedMinutes: 30,
          ),
        ],
      ),
      const TimelineBucketModel(
        name: 'Afternoon',
        timeRange: '12:00 PM - 5:00 PM',
        tasks: [],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimelineScheduleSection(
            timelineBuckets: buckets,
            onToggleComplete: (_) {},
            onMoveToToday: (_) {},
            isViewingToday: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Timeline & Schedule'), findsOneWidget);
    expect(find.text('Morning'), findsOneWidget);
    expect(find.text('Afternoon'), findsOneWidget);
    expect(find.text('Morning Daily Scrum'), findsOneWidget);
    expect(find.text('No tasks scheduled for afternoon'), findsOneWidget);
  });

  testWidgets('WeeklyPreviewSection displays 7-day overview with due counts',
      (WidgetTester tester) async {
    const weeklyPlan = WeeklyPlanModel(
      startDate: '2026-08-17',
      endDate: '2026-08-23',
      totalTasks: 8,
      completedTasks: 3,
      days: [
        WeeklyDayModel(
          date: '2026-08-17',
          dayName: 'Monday',
          taskCount: 3,
          dueCount: 3,
          completedCount: 2,
          hasCritical: true,
        ),
        WeeklyDayModel(
          date: '2026-08-18',
          dayName: 'Tuesday',
          taskCount: 5,
          dueCount: 5,
          completedCount: 1,
          hasCritical: false,
        ),
      ],
    );

    DateTime? selectedDate;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyPreviewSection(
            weeklyPlan: weeklyPlan,
            onSelectDate: (d) => selectedDate = d,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Weekly Overview'), findsOneWidget);
    expect(find.text('3/8 Done'), findsOneWidget);
    expect(find.text('MON'), findsOneWidget);
    expect(find.text('TUE'), findsOneWidget);
    expect(find.text('Due: '), findsNWidgets(2));

    // Tap on Tuesday card
    await tester.tap(find.text('TUE'));
    expect(selectedDate?.day, equals(18));
  });
}
