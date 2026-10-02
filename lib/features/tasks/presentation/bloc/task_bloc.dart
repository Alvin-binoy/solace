import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
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

    // emit.forEach keeps a live connection to the Stream!
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
    final result = await _addTask(event.task);
    if (result.isLeft()) {
      // If adding fails, we briefly emit an error state
      final failure = result.fold((l) => l, (r) => null)!;
      // We don't overwrite the whole state here permanently,
      // but in a more advanced setup we might emit a side-effect.
      // For now, let's just log it or rely on the stream.
    }
  }

  Future<void> _onUpdateTask(UpdateTaskEvent event, Emitter<TaskState> emit) async {
    await _updateTask(event.task);
  }

  Future<void> _onDeleteTask(DeleteTaskEvent event, Emitter<TaskState> emit) async {
    await _deleteTask(event.id);
  }
}