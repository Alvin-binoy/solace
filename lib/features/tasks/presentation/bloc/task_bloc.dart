import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/enums/task_status.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/use_cases/add_task_use_case.dart';
import '../../domain/use_cases/delete_task_use_case.dart';
import '../../domain/use_cases/update_task_use_case.dart';
import '../../domain/use_cases/watch_all_tasks_use_case.dart';
import 'task_event.dart';
import 'task_state.dart';

@injectable
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final WatchAllTasksUseCase _watchAllTasks;
  final AddTaskUseCase _addTask;
  final UpdateTaskUseCase _updateTask;
  final DeleteTaskUseCase _deleteTask;

  final NotificationService _notificationService = NotificationService();

  TaskBloc(
      this._watchAllTasks,
      this._addTask,
      this._updateTask,
      this._deleteTask,
      ) : super(TaskInitial()) {
    on<WatchTasksEvent>(_onWatchTasks);
    on<AddTaskEvent>(_onAddTask);
    on<UpdateTaskEvent>(_onUpdateTask);
    on<DeleteTaskEvent>(_onDeleteTask);
  }

  Future<void> _onWatchTasks(WatchTasksEvent event, Emitter<TaskState> emit) async {
    emit(TaskLoading());

    await emit.forEach<Either<Failure, List<TaskEntity>>>(
      _watchAllTasks(),
      onData: (result) => result.fold(
            (failure) => TaskError(failure.message),
            (tasks) => TaskLoaded(tasks),
      ),
      onError: (_, __) => const TaskError('An unexpected error occurred loading tasks.'),
    );
  }

  Future<void> _onAddTask(AddTaskEvent event, Emitter<TaskState> emit) async {
    await _addTask(event.task);
    await _handleTaskNotification(event.task);
  }

  Future<void> _onUpdateTask(UpdateTaskEvent event, Emitter<TaskState> emit) async {
    TaskEntity taskToSave = event.task;

    // --- RECURRING TASKS LOGIC ---
    // If a task is being marked as COMPLETED, and it is a recurring task:
    if (taskToSave.status == TaskStatus.completed &&
        taskToSave.isRecurring &&
        taskToSave.recurrenceRule != null) {

      // 1. Spawn the next instance!
      _spawnNextRecurringTask(taskToSave);

      // 2. Detach the recurrence rule from THIS completed instance
      // so it doesn't accidentally spawn again if you uncheck/recheck it later.
      taskToSave = taskToSave.copyWith(
          isRecurring: false,
          recurrenceRule: null
      );
    }

    await _updateTask(taskToSave);
    await _handleTaskNotification(taskToSave);
  }

  Future<void> _onDeleteTask(DeleteTaskEvent event, Emitter<TaskState> emit) async {
    await _deleteTask(event.id);
    await _notificationService.cancelReminder(event.id.hashCode);
  }

  // --- RECURRING TASK SPAWNER ---

  void _spawnNextRecurringTask(TaskEntity completedTask) {
    final ruleString = completedTask.recurrenceRule;
    if (ruleString == null) return;

    final baseDateRaw = completedTask.scheduledAt ?? completedTask.deadline ?? completedTask.startTime;
    if (baseDateRaw == null) return;

    // Strip the time to guarantee pure calendar math
    final baseDate = DateTime(baseDateRaw.year, baseDateRaw.month, baseDateRaw.day);

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    DateTime nextDate = baseDate;

    // Fast-forward past overdue dates, and use DST-safe calendar math
    while (nextDate.isBefore(startOfToday) || nextDate.isAtSameMomentAs(baseDate)) {
      if (ruleString.contains('DAILY')) {
        nextDate = DateTime(nextDate.year, nextDate.month, nextDate.day + 1);
      } else if (ruleString.contains('WEEKLY')) {
        nextDate = DateTime(nextDate.year, nextDate.month, nextDate.day + 7);
      } else if (ruleString.contains('MONTHLY')) {
        // Month rollover clamping (Jan 31 -> Feb 28)
        int nextMonth = nextDate.month + 1;
        int nextYear = nextDate.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }

        int daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        int targetDay = baseDate.day > daysInNextMonth ? daysInNextMonth : baseDate.day;

        nextDate = DateTime(nextYear, nextMonth, targetDay);
      } else {
        break;
      }
    }

    // EDGE CASE FIX 1: Safely transfer times, preserving multi-day spans (Overnight Tasks)
    DateTime? shiftTime(DateTime? original) {
      if (original == null) return null;

      // Calculate if the original time spilled into the next day
      final originalDateOnly = DateTime(original.year, original.month, original.day);
      final dayOffset = originalDateOnly.difference(baseDate).inDays;

      return DateTime(
          nextDate.year,
          nextDate.month,
          nextDate.day + dayOffset, // Applies the overnight jump perfectly!
          original.hour,
          original.minute
      );
    }

    // Clone the task with the new future dates and a guaranteed unique ID
    final nextTask = completedTask.copyWith(
      id: const Uuid().v4(),
      // EDGE CASE FIX 2: Link the new clone back to the original parent!
      parentTaskId: completedTask.parentTaskId ?? completedTask.id,
      status: TaskStatus.pending,
      scheduledAt: shiftTime(completedTask.scheduledAt),
      startTime: shiftTime(completedTask.startTime),
      endTime: shiftTime(completedTask.endTime),
      deadline: shiftTime(completedTask.deadline),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    add(AddTaskEvent(nextTask));
  }

  // --- NOTIFICATIONS ---

  Future<void> _handleTaskNotification(TaskEntity task) async {
    final notificationId = task.id.hashCode;

    if (task.status == TaskStatus.completed) {
      await _notificationService.cancelReminder(notificationId);
      return;
    }

    final reminderTime = _calculateReminderTime(task);

    if (reminderTime != null && reminderTime.isAfter(DateTime.now())) {
      await _notificationService.scheduleTaskReminder(
        id: notificationId,
        title: task.title,
        body: task.description.isNotEmpty ? task.description : 'Task Reminder',
        scheduledDate: reminderTime,
      );
    } else {
      await _notificationService.cancelReminder(notificationId);
    }
  }

  DateTime? _calculateReminderTime(TaskEntity task) {
    final baseTime = task.startTime ?? task.scheduledAt ?? task.deadline;
    if (baseTime == null) return null;

    if (task.reminderLeadMinutes != null) {
      return baseTime.subtract(Duration(minutes: task.reminderLeadMinutes!));
    }

    return baseTime;
  }
}