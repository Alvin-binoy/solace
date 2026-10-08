import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/task_status.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/bloc/task_bloc.dart';
import '../../../tasks/presentation/bloc/task_event.dart';
import '../../domain/services/workload_planner_service.dart';

class DailyPlannerBottomSheet extends StatefulWidget {
  final List<TaskEntity> todaysTasks;

  const DailyPlannerBottomSheet({super.key, required this.todaysTasks});

  static void show(BuildContext context, List<TaskEntity> todaysTasks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DailyPlannerBottomSheet(todaysTasks: todaysTasks),
    );
  }

  @override
  State<DailyPlannerBottomSheet> createState() => _DailyPlannerBottomSheetState();
}

class _DailyPlannerBottomSheetState extends State<DailyPlannerBottomSheet> {
  double _availableHours = 4.0;
  bool _hasPlanned = false;
  DailyPlanResult? _planResult;

  int _calculateRequiredWorkload() {
    int totalMins = 0;
    for (var task in widget.todaysTasks) {
      if (task.status == TaskStatus.completed) continue;
      if (task.startTime != null && task.endTime != null) {
        totalMins += task.endTime!.difference(task.startTime!).inMinutes;
      } else {
        totalMins += task.estimatedDurationMinutes ?? 30;
      }
    }
    return totalMins;
  }

  void _generatePlan() {
    final planner = GetIt.I<WorkloadPlannerService>();
    final result = planner.generatePlan(
      todaysTasks: widget.todaysTasks,
      availableMinutes: (_availableHours * 60).toInt(),
    );

    setState(() {
      _planResult = result;
      _hasPlanned = true;
    });
  }

  void _postponeTasks() {
    // If there is a deadline risk, confirm before moving to tomorrow
    if (_planResult!.hasDeadlineRisk) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Deadline Warning'),
          content: const Text('Some postponed tasks are due TODAY. Are you sure you want to push them to tomorrow?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _executePostpone();
              },
              child: const Text('Move Anyway', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      _executePostpone();
    }
  }

  void _executePostpone() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    for (var task in _planResult!.postponedFlexible) {
      context.read<TaskBloc>().add(UpdateTaskEvent(task.copyWith(
        scheduledAt: tomorrow,
        deadline: (task.deadline != null && task.deadline!.isBefore(tomorrow))
            ? tomorrow
            : task.deadline,
      )));
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tasks postponed to tomorrow!'), backgroundColor: Colors.green),
    );
  }

  String _formatMins(int mins) {
    final hours = mins ~/ 60;
    final remainingMins = mins % 60;
    if (hours > 0 && remainingMins > 0) return '${hours}h ${remainingMins}m';
    if (hours > 0) return '${hours}h';
    return '${remainingMins}m';
  }

  Widget _buildWarningBanner(String message, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final requiredMins = _calculateRequiredWorkload();

    return Container(
      padding: const EdgeInsets.all(24.0),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.purple, size: 28),
              const SizedBox(width: 12),
              const Text('Daily Workload Planner', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),

          if (!_hasPlanned) ...[
            Text(
              'What can you realistically complete today?',
              style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: requiredMins > (_availableHours * 60) ? Colors.orange : Colors.transparent),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Workload:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(_formatMins(requiredMins), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Available Time:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${_availableHours.toStringAsFixed(1)} hours', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Slide to set your free time:', style: TextStyle(fontWeight: FontWeight.w600)),
            Slider(
              value: _availableHours,
              min: 1.0,
              max: 16.0,
              divisions: 30,
              label: '${_availableHours.toStringAsFixed(1)} hrs',
              onChanged: (val) => setState(() => _availableHours = val),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _generatePlan,
                icon: const Icon(Icons.science),
                label: const Text('Generate Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ] else ...[
            // RESULTS VIEW

            // Smart Edge Case Warnings
            if (_planResult!.hasTimeBlockConflicts)
              _buildWarningBanner('Schedule Conflict: You have overlapping time blocks!', Colors.red, Icons.error_outline),

            if (_planResult!.isOverCapacity)
              _buildWarningBanner('Over Capacity: Your scheduled meetings exceed your selected free time!', Colors.orange, Icons.warning_amber),

            if (_planResult!.hasOversizedTasks)
              _buildWarningBanner('Oversized Task: A task is larger than your total free time. Break it down!', Colors.blue, Icons.compress),

            if (_planResult!.hasDeadlineRisk)
              _buildWarningBanner('Deadline Risk: You are postponing tasks that are due today!', Colors.deepOrange, Icons.timer_off),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('Scheduled', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(height: 4),
                      Text(_formatMins(_planResult!.totalScheduledMinutes), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(height: 30, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
                  Column(
                    children: [
                      const Text('Free Time Left', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(_formatMins(_planResult!.remainingFreeMinutes), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  if (_planResult!.hardScheduled.isNotEmpty || _planResult!.suggestedFlexible.isNotEmpty) ...[
                    const Text(" Today's Plan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ..._planResult!.hardScheduled.map((t) => _buildSimpleTaskTile(t, true)),
                    ..._planResult!.suggestedFlexible.map((t) => _buildSimpleTaskTile(t, true)),
                  ],
                  if (_planResult!.postponedFlexible.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(" Postponed (Doesn't fit)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                    const SizedBox(height: 12),
                    ..._planResult!.postponedFlexible.map((t) => _buildSimpleTaskTile(t, false)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _postponeTasks,
                        icon: const Icon(Icons.next_plan),
                        label: const Text('Move these to Tomorrow'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleTaskTile(TaskEntity task, bool fits) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        fits ? Icons.check_circle : Icons.radio_button_unchecked,
        color: fits ? Colors.green : Colors.grey,
      ),
      title: Text(task.title, style: TextStyle(fontWeight: fits ? FontWeight.bold : FontWeight.normal)),
      trailing: Text(
        _formatMins(
            (task.startTime != null && task.endTime != null)
                ? task.endTime!.difference(task.startTime!).inMinutes
                : (task.estimatedDurationMinutes ?? 30)
        ),
        style: TextStyle(color: fits ? Theme.of(context).colorScheme.onSurface : Colors.grey),
      ),
    );
  }
}