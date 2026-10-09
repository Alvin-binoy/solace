import 'package:injectable/injectable.dart';
import '../../../../core/enums/task_priority.dart';
import '../../../../core/enums/task_category.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

@lazySingleton
class PriorityEngine {
  final TaskRepository _repository;

  PriorityEngine(this._repository);

  /// Analyzes all pending tasks and auto-escalates their priority based on business rules.
  Future<void> execute() async {
    final result = await _repository.getPendingTasks();

    result.fold(
          (failure) => null, // Silently ignore errors if running in background
          (tasks) async {
        final now = DateTime.now();

        for (var task in tasks) {
          TaskPriority newPriority = task.priority;

          // RULE 1: Health tasks should never be lower than Medium
          if (task.category == TaskCategory.health && newPriority == TaskPriority.low) {
            newPriority = TaskPriority.medium;
          }

          // RULE 2: Stale Tasks - For every 3 days a task sits pending, bump it up 1 priority level
          final daysPending = now.difference(task.createdAt).inDays;
          if (daysPending >= 3) {
            final bumpLevels = daysPending ~/ 3; // e.g., 3 days = +1 level, 6 days = +2 levels
            final newIndex = (newPriority.index + bumpLevels).clamp(0, TaskPriority.urgent.index);
            newPriority = TaskPriority.values[newIndex];
          }

          // RULE 3: Imminent Deadline - If due in less than 24 hours, force it to URGENT
          if (task.deadline != null) {
            final hoursUntilDeadline = task.deadline!.difference(now).inHours;
            // If it's due within 24 hours (or already past due but still pending)
            if (hoursUntilDeadline <= 24) {
              newPriority = TaskPriority.urgent;
            }
          }

          // Only update the database if the engine actually increased the priority
          if (newPriority != task.priority && newPriority.index > task.priority.index) {
            final updatedTask = task.copyWith(
              priority: newPriority,
              updatedAt: now,
            );
            await _repository.updateTask(updatedTask);
          }
        }
      },
    );
  }
}