import 'package:equatable/equatable.dart';
import '../../domain/entities/task_entity.dart';

sealed class TaskEvent extends Equatable {
  const TaskEvent();
  @override
  List<Object> get props => [];
}

class WatchTasksEvent extends TaskEvent {}

class AddTaskEvent extends TaskEvent {
  final TaskEntity task;
  const AddTaskEvent(this.task);
  @override
  List<Object> get props => [task];
}

class UpdateTaskEvent extends TaskEvent {
  final TaskEntity task;
  const UpdateTaskEvent(this.task);
  @override
  List<Object> get props => [task];
}

class DeleteTaskEvent extends TaskEvent {
  final String id;
  const DeleteTaskEvent(this.id);
  @override
  List<Object> get props => [id];
}