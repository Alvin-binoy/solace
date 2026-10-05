import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/enums/task_status.dart'; // NEW: Imported to check if task is completed
import '../../../../core/services/notification_service.dart'; // NEW: Imported the notification service
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

  // NEW: Get the notification service instance
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
    await _handleTaskNotification(event.task); // NEW: Schedule alarm on create
  }

  Future<void> _onUpdateTask(UpdateTaskEvent event, Emitter<TaskState> emit) async {
    await _updateTask(event.task);
    await _handleTaskNotification(event.task); // NEW: Reschedule/cancel alarm on update
  }

  Future<void> _onDeleteTask(DeleteTaskEvent event, Emitter<TaskState> emit) async {
    await _deleteTask(event.id);
    await _notificationService.cancelReminder(event.id.hashCode); // NEW: Cancel alarm on delete
  }

  // --- NEW HELPER METHODS FOR NOTIFICATIONS ---

  Future<void> _handleTaskNotification(TaskEntity task) async {
    // flutter_local_notifications requires an integer ID.
    // String.hashCode safely converts your String UUID to an int.
    final notificationId = task.id.hashCode;

    // If task is completed, cancel any existing alarms and exit
    if (task.status == TaskStatus.completed) {
      await _notificationService.cancelReminder(notificationId);
      return;
    }

    // Calculate exactly when the alarm should go off
    final reminderTime = _calculateReminderTime(task);

    if (reminderTime != null && reminderTime.isAfter(DateTime.now())) {
      await _notificationService.scheduleTaskReminder(
        id: notificationId,
        title: task.title,
        body: task.description.isNotEmpty ? task.description : 'Task Reminder',
        scheduledDate: reminderTime,
      );
    } else {
      // If time is in the past, or time was removed, ensure alarm is cancelled
      await _notificationService.cancelReminder(notificationId);
    }
  }

  DateTime? _calculateReminderTime(TaskEntity task) {
    // Determine the base target time. We prioritize startTime, then scheduledAt, then deadline.
    final baseTime = task.startTime ?? task.scheduledAt ?? task.deadline;

    if (baseTime == null) return null;

    // If user set a lead time (e.g., remind 15 mins early), subtract it from the base time
    if (task.reminderLeadMinutes != null) {
      return baseTime.subtract(Duration(minutes: task.reminderLeadMinutes!));
    }

    // Default to the exact time if no lead minutes are specified
    return baseTime;
  }
}