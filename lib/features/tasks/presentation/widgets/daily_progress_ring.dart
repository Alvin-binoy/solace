import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/enums/task_status.dart';
import '../../domain/entities/task_entity.dart';

class DailyProgressRing extends StatelessWidget {
  final List<TaskEntity> tasks;

  const DailyProgressRing({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    // Edge Case: Filter tasks scheduled strictly for TODAY
    final now = DateTime.now();
    final todaysTasks = tasks.where((t) {
      final dateToUse = t.startTime ?? t.scheduledAt ?? t.deadline;
      if (dateToUse == null) return false;
      return dateToUse.year == now.year &&
          dateToUse.month == now.month &&
          dateToUse.day == now.day;
    }).toList();

    final completed = todaysTasks.where((t) => t.status == TaskStatus.completed).length;
    final total = todaysTasks.length;

    // Fallback UI if there are no tasks today
    if (total == 0) {
      return _buildEmptyRing(context);
    }

    final double completionPercentage = (completed / total) * 100;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 45,
                    startDegreeOffset: -90, // Start drawing from the top
                    sections: [
                      PieChartSectionData(
                        color: Theme.of(context).colorScheme.primary,
                        value: completed.toDouble(),
                        title: '',
                        radius: 14,
                      ),
                      PieChartSectionData(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        value: (total - completed).toDouble(),
                        title: '',
                        radius: 14,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${completionPercentage.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Progress",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "$completed of $total tasks completed",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 16),
                if (completed == total)
                  const Text("All done!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600))
                else
                  Text("Keep going!", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600))
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRing(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 45,
                    sections: [
                      PieChartSectionData(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        value: 1,
                        title: '',
                        radius: 14,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.nightlight_round, color: Colors.grey.shade600),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("No tasks scheduled for today.", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}