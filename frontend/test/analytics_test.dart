import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/analytics/domain/analytics_model.dart';

void main() {
  group('Analytics Models Test', () {
    test('AnalyticsOverviewModel parsing test', () {
      final json = {
        'streaks': {
          'current_streak': 5,
          'longest_streak': 14,
        },
        'personal_records': {
          'best_day_tasks': 10,
          'best_day_focus_minutes': 300,
          'longest_streak': 14,
        },
        'goals_summary': {
          'active_goals': 3,
          'completed_goals': 1,
          'total_goals': 4,
          'goal_completion_rate': 25.0,
          'completed_milestones': 6,
          'total_milestones': 10,
          'milestone_completion_rate': 60.0,
        },
        'focus_time': {
          'today_minutes': 120,
          'week_minutes': 600,
          'month_minutes': 2400,
        },
        'productivity_insights': {
          'most_productive_day': 'Tuesday',
          'most_productive_window': 'Evening',
          'most_productive_window_percentage': 45.5,
        },
        'completion_stats': {
          'total_completed_tasks': 25,
          'total_due_tasks': 30,
          'overall_completion_rate': 83.3,
          'on_time_completion_rate': 90.0,
          'overdue_completion_rate': 10.0,
        },
      };

      final overview = AnalyticsOverviewModel.fromJson(json);

      expect(overview.streaks.currentStreak, 5);
      expect(overview.streaks.longestStreak, 14);
      expect(overview.personalRecords.bestDayTasks, 10);
      expect(overview.personalRecords.bestDayFocusMinutes, 300);
      expect(overview.goalsSummary.activeGoals, 3);
      expect(overview.goalsSummary.goalCompletionRate, 25.0);
      expect(overview.focusTime.todayMinutes, 120);
      expect(overview.productivityInsights.mostProductiveDay, 'Tuesday');
      expect(overview.completionStats.overallCompletionRate, 83.3);
    });

    test('WeeklyAnalyticsModel parsing test', () {
      final json = {
        'days': [
          {
            'date': '2026-08-20',
            'day_label': 'Thu',
            'completed_count': 4,
            'total_due_count': 5,
            'completion_rate': 80.0,
            'completed_minutes': 180,
          }
        ],
        'time_of_day_breakdown': {
          'morning': 5,
          'afternoon': 10,
          'evening': 15,
          'night': 2,
        },
      };

      final weekly = WeeklyAnalyticsModel.fromJson(json);

      expect(weekly.days.length, 1);
      expect(weekly.days.first.dayLabel, 'Thu');
      expect(weekly.days.first.completionRate, 80.0);
      expect(weekly.timeOfDayBreakdown.evening, 15);
    });

    test('AnalyticsHeatmapModel parsing test', () {
      final json = {
        'heatmap': [
          {'date': '2026-08-20', 'count': 5, 'level': 3}
        ],
      };

      final heatmap = AnalyticsHeatmapModel.fromJson(json);

      expect(heatmap.heatmap.length, 1);
      expect(heatmap.heatmap.first.count, 5);
      expect(heatmap.heatmap.first.level, 3);
    });
  });
}
