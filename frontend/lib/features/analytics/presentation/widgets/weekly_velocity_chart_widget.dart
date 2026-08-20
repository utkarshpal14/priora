import 'package:flutter/material.dart';
import 'package:frontend/features/analytics/domain/analytics_model.dart';

class WeeklyVelocityChartWidget extends StatelessWidget {
  final WeeklyAnalyticsModel weekly;

  const WeeklyVelocityChartWidget({super.key, required this.weekly});

  @override
  Widget build(BuildContext context) {
    final maxTasks = weekly.days.fold<int>(1, (max, d) => d.completedCount > max ? d.completedCount : max);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart_rounded, color: Color(0xFF3B82F6), size: 22),
                  SizedBox(width: 8),
                  Text(
                    '7-Day Completion Velocity & Trend 📊',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (weekly.days.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No velocity data available', style: TextStyle(color: Colors.white54)),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: weekly.days.map((day) => _buildBar(context, day, maxTasks)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBar(BuildContext context, WeeklyDayModel day, int maxTasks) {
    final heightRatio = (day.completedCount / maxTasks).clamp(0.1, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${day.completionRate.toInt()}%',
          style: TextStyle(
            color: day.completionRate >= 80 ? const Color(0xFF10B981) : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: 110 * heightRatio,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF3B82F6),
                const Color(0xFF3B82F6).withOpacity(0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '${day.completedCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day.dayLabel,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
