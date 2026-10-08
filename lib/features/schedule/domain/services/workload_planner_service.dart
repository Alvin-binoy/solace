import 'package:injectable/injectable.dart';
import '../../../../core/enums/task_priority.dart';
import '../../../../core/enums/task_status.dart';
import '../../../tasks/domain/entities/task_entity.dart';

class DailyPlanResult {
  final List<TaskEntity> hardScheduled;
  final List<TaskEntity> suggestedFlexible;
  final List<TaskEntity> postponedFlexible;
  final int totalScheduledMinutes;
  final int remainingFreeMinutes;

  // The Edge Case Flags
  final bool hasTimeBlockConflicts;
  final bool isOverCapacity;
  final bool hasOversizedTasks;
  final bool hasDeadlineRisk;

  DailyPlanResult({
    required this.hardScheduled,
    required this.suggestedFlexible,
    required this.postponedFlexible,
    required this.totalScheduledMinutes,
    required this.remainingFreeMinutes,
    required this.hasTimeBlockConflicts,
    required this.isOverCapacity,
    required this.hasOversizedTasks,
    required this.hasDeadlineRisk,
  });
}

@lazySingleton
class WorkloadPlannerService {

  DailyPlanResult generatePlan({
    required List<TaskEntity> todaysTasks,
    required int availableMinutes,
  }) {
    List<TaskEntity> hardScheduled = [];
    List<TaskEntity> flexibleTasks = [];
    List<TaskEntity> suggestedFlexible = [];
    List<TaskEntity> postponedFlexible = [];

    bool hasOversizedTasks = false;
    bool hasDeadlineRisk = false;
    final now = DateTime.now();

    // 1. Separate tasks
    for (var task in todaysTasks) {
      if (task.status == TaskStatus.completed) continue;
      if (task.startTime != null && task.endTime != null) {
        hardScheduled.add(task);
      } else {
        flexibleTasks.add(task);
      }
    }

    // 2. Interval Merging & Collision Detection
    final (blockedMinutes, hasConflicts) = _calculateTrueBlockedMinutes(hardScheduled);

    // NEW: Check for Over-Capacity
    bool isOverCapacity = blockedMinutes > availableMinutes;

    int timeRemaining = availableMinutes - blockedMinutes;
    if (timeRemaining < 0) timeRemaining = 0;

    int timeUsed = blockedMinutes;

    // 3. Sort flexible tasks (Greedy)
    flexibleTasks.sort((a, b) {
      final pA = _getPriorityWeight(a.priority);
      final pB = _getPriorityWeight(b.priority);
      if (pA != pB) return pB.compareTo(pA);

      if (a.deadline != null && b.deadline != null) {
        final deadlineCompare = a.deadline!.compareTo(b.deadline!);
        if (deadlineCompare != 0) return deadlineCompare;
      } else if (a.deadline != null) {
        return -1;
      } else if (b.deadline != null) {
        return 1;
      }

      final durA = a.estimatedDurationMinutes ?? 30;
      final durB = b.estimatedDurationMinutes ?? 30;
      return durA.compareTo(durB);
    });

    // 4. Pack the Knapsack & Check Constraints
    for (var task in flexibleTasks) {
      final taskDuration = task.estimatedDurationMinutes ?? 30;

      // NEW: Check for Oversized Task (impossible to complete even with full day)
      if (taskDuration > availableMinutes) {
        hasOversizedTasks = true;
      }

      if (taskDuration <= timeRemaining) {
        suggestedFlexible.add(task);
        timeRemaining -= taskDuration;
        timeUsed += taskDuration;
      } else {
        postponedFlexible.add(task);

        // NEW: Check for Missed Deadline Risk
        if (task.deadline != null) {
          if (task.deadline!.year == now.year &&
              task.deadline!.month == now.month &&
              task.deadline!.day == now.day) {
            hasDeadlineRisk = true;
          }
        }
      }
    }

    return DailyPlanResult(
      hardScheduled: hardScheduled,
      suggestedFlexible: suggestedFlexible,
      postponedFlexible: postponedFlexible,
      totalScheduledMinutes: timeUsed,
      remainingFreeMinutes: timeRemaining,
      hasTimeBlockConflicts: hasConflicts,
      isOverCapacity: isOverCapacity,
      hasOversizedTasks: hasOversizedTasks,
      hasDeadlineRisk: hasDeadlineRisk,
    );
  }

  (int, bool) _calculateTrueBlockedMinutes(List<TaskEntity> tasks) {
    if (tasks.isEmpty) return (0, false);
    bool hasConflicts = false;
    List<List<DateTime>> intervals = tasks.map((t) => [t.startTime!, t.endTime!]).toList();
    intervals.sort((a, b) => a[0].compareTo(b[0]));
    List<List<DateTime>> merged = [intervals.first];

    for (int i = 1; i < intervals.length; i++) {
      var current = intervals[i];
      var lastMerged = merged.last;
      if (current[0].isBefore(lastMerged[1])) {
        hasConflicts = true;
        if (current[1].isAfter(lastMerged[1])) lastMerged[1] = current[1];
      } else if (current[0].isAtSameMomentAs(lastMerged[1])) {
        if (current[1].isAfter(lastMerged[1])) lastMerged[1] = current[1];
      } else {
        merged.add(current);
      }
    }
    int totalMinutes = 0;
    for (var interval in merged) {
      totalMinutes += interval[1].difference(interval[0]).inMinutes;
    }
    return (totalMinutes, hasConflicts);
  }

  int _getPriorityWeight(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent: return 4;
      case TaskPriority.high: return 3;
      case TaskPriority.medium: return 2;
      case TaskPriority.low: return 1;
    }
  }
}