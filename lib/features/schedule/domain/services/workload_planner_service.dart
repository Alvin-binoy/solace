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
  final bool hasTimeBlockConflicts; // NEW: The collision flag

  DailyPlanResult({
    required this.hardScheduled,
    required this.suggestedFlexible,
    required this.postponedFlexible,
    required this.totalScheduledMinutes,
    required this.remainingFreeMinutes,
    required this.hasTimeBlockConflicts,
  });
}

@lazySingleton
class WorkloadPlannerService {

  /// Generates an optimized daily schedule based on available time and task priority.
  DailyPlanResult generatePlan({
    required List<TaskEntity> todaysTasks,
    required int availableMinutes,
  }) {
    List<TaskEntity> hardScheduled = [];
    List<TaskEntity> flexibleTasks = [];
    List<TaskEntity> suggestedFlexible = [];
    List<TaskEntity> postponedFlexible = [];

    // 1. Separate tasks and filter out completed ones
    for (var task in todaysTasks) {
      if (task.status == TaskStatus.completed) continue;

      if (task.startTime != null && task.endTime != null) {
        hardScheduled.add(task);
      } else {
        flexibleTasks.add(task);
      }
    }

    // 2. Calculate true blocked time using Interval Merging, and detect collisions!
    final (blockedMinutes, hasConflicts) = _calculateTrueBlockedMinutes(hardScheduled);

    int timeRemaining = availableMinutes - blockedMinutes;
    if (timeRemaining < 0) timeRemaining = 0;

    int timeUsed = blockedMinutes;

    // 3. Sort the flexible tasks (Greedy approach)
    flexibleTasks.sort((a, b) {
      // Primary Sort: Priority (Urgent > High > Medium > Low)
      final pA = _getPriorityWeight(a.priority);
      final pB = _getPriorityWeight(b.priority);
      if (pA != pB) return pB.compareTo(pA); // Descending

      // Secondary Sort: Deadline (Earliest deadline first)
      if (a.deadline != null && b.deadline != null) {
        final deadlineCompare = a.deadline!.compareTo(b.deadline!);
        if (deadlineCompare != 0) return deadlineCompare;
      } else if (a.deadline != null) {
        return -1; // 'a' has a deadline, 'b' doesn't, so 'a' goes first
      } else if (b.deadline != null) {
        return 1;
      }

      // Tertiary Sort: Duration (Quickest tasks first to maximize dopamine/completion count)
      final durA = a.estimatedDurationMinutes ?? 30;
      final durB = b.estimatedDurationMinutes ?? 30;
      return durA.compareTo(durB);
    });

    // 4. Pack the knapsack! (Allocate flexible tasks into remaining time)
    for (var task in flexibleTasks) {
      final taskDuration = task.estimatedDurationMinutes ?? 30;

      if (taskDuration <= timeRemaining) {
        // It fits!
        suggestedFlexible.add(task);
        timeRemaining -= taskDuration;
        timeUsed += taskDuration;
      } else {
        // It doesn't fit, postpone it.
        postponedFlexible.add(task);
      }
    }

    return DailyPlanResult(
      hardScheduled: hardScheduled,
      suggestedFlexible: suggestedFlexible,
      postponedFlexible: postponedFlexible,
      totalScheduledMinutes: timeUsed,
      remainingFreeMinutes: timeRemaining,
      hasTimeBlockConflicts: hasConflicts, // Passing the flag to the UI
    );
  }

  /// Returns (Total Merged Minutes, Has Conflicts Flag)
  (int, bool) _calculateTrueBlockedMinutes(List<TaskEntity> tasks) {
    if (tasks.isEmpty) return (0, false);

    bool hasConflicts = false;

    // Create a list of start/end intervals
    List<List<DateTime>> intervals = tasks.map((t) => [t.startTime!, t.endTime!]).toList();

    // Sort intervals by start time
    intervals.sort((a, b) => a[0].compareTo(b[0]));

    List<List<DateTime>> merged = [intervals.first];

    for (int i = 1; i < intervals.length; i++) {
      var current = intervals[i];
      var lastMerged = merged.last;

      // STRICT OVERLAP CHECK: Does the current task start BEFORE the last task ended?
      if (current[0].isBefore(lastMerged[1])) {
        hasConflicts = true; // Collision detected!
        // Extend the end time if the current block ends later
        if (current[1].isAfter(lastMerged[1])) {
          lastMerged[1] = current[1];
        }
      } else if (current[0].isAtSameMomentAs(lastMerged[1])) {
        // They touch exactly back-to-back. Merge them, but no conflict warning.
        if (current[1].isAfter(lastMerged[1])) {
          lastMerged[1] = current[1];
        }
      } else {
        // No overlap, add as a new block
        merged.add(current);
      }
    }

    // Sum up the total minutes of all distinct, merged blocks
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