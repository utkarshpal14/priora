import 'package:flutter/material.dart';
import 'package:frontend/features/analytics/domain/analytics_model.dart';

class CategoryBreakdownWidget extends StatelessWidget {
  final AnalyticsBreakdownModel breakdown;

  const CategoryBreakdownWidget({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
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
            children: [
              Icon(Icons.pie_chart_rounded, color: Color(0xFF8B5CF6), size: 22),
              SizedBox(width: 8),
              Text(
                'Category Distribution 🎨',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (breakdown.categories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No categories data available', style: TextStyle(color: Colors.white54)),
            )
          else
            Column(
              children: breakdown.categories.map((cat) => _buildCategoryRow(cat)).toList(),
            ),
          const SizedBox(height: 20),
          const Text(
            'Tasks Completed by Priority',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPriorityChip('Critical', breakdown.priorities.critical, const Color(0xFFEF4444)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPriorityChip('High', breakdown.priorities.high, const Color(0xFFF97316)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPriorityChip('Medium', breakdown.priorities.medium, const Color(0xFFEAB308)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPriorityChip('Low', breakdown.priorities.low, const Color(0xFF10B981)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(CategoryBreakdownItemModel cat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: cat.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cat.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Text(
                '${cat.count} tasks (${cat.percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (cat.percentage / 100.0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFF0F172A),
              valueColor: AlwaysStoppedAnimation<Color>(cat.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
