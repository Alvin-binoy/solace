import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/enums/task_status.dart';
import '../../domain/entities/task_entity.dart';

class WeeklyBarChart extends StatelessWidget {
  final List<TaskEntity> tasks;

  const WeeklyBarChart({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    List<BarChartGroupData> barGroups = [];
    double maxY = 0;

    for (int i = 6; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));

      final completedCount = tasks.where((t) {
        if (t.status != TaskStatus.completed || t.updatedAt == null) return false;
        return t.updatedAt!.year == targetDate.year &&
            t.updatedAt!.month == targetDate.month &&
            t.updatedAt!.day == targetDate.day;
      }).length.toDouble();

      if (completedCount > maxY) maxY = completedCount;

      barGroups.add(
        BarChartGroupData(
          x: 6 - i,
          barRods: [
            BarChartRodData(
              toY: completedCount,
              color: i == 0 ? Theme.of(context).colorScheme.primary : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
              width: 14,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY > 5 ? maxY + 2 : 5, // Ensures there is always a track behind the bar
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tasks Completed (Last 7 Days)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide Y axis clutter
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final date = now.subtract(Duration(days: 6 - value.toInt()));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('E').format(date).substring(0, 1), // M, T, W, T, F, S, S
                            style: TextStyle(
                              color: value.toInt() == 6 ? Theme.of(context).colorScheme.primary : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                alignment: BarChartAlignment.spaceAround,
              ),
            ),
          ),
        ],
      ),
    );
  }
}