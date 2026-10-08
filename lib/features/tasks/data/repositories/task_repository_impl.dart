import 'package:fpdart/fpdart.dart' hide Task;
import 'package:injectable/injectable.dart';
import 'package:drift/drift.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_datasource.dart';

@Injectable(as: TaskRepository)
class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDatasource _datasource;

  TaskRepositoryImpl(this._datasource);

  TaskEntity _toEntity(Task model) {
    return TaskEntity(
      id: model.id,
      title: model.title,
      description: model.description ?? '',
      priority: model.priority,
      category: model.category,
      status: model.status,
      deadline: model.deadline,
      scheduledAt: model.scheduledAt,
      startTime: model.startTime,
      endTime: model.endTime,
      estimatedDurationMinutes: model.estimatedDurationMinutes, // NEW
      isRecurring: model.isRecurring,
      recurrenceRule: model.recurrenceRule,
      parentTaskId: model.parentTaskId,
      reminderLeadMinutes: model.reminderLeadMinutes,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  TasksCompanion _toCompanion(TaskEntity entity) {
    return TasksCompanion(
      id: Value(entity.id),
      title: Value(entity.title),
      description: Value(entity.description.isEmpty ? null : entity.description),
      priority: Value(entity.priority),
      category: Value(entity.category),
      status: Value(entity.status),
      deadline: Value(entity.deadline),
      scheduledAt: Value(entity.scheduledAt),
      startTime: Value(entity.startTime),
      endTime: Value(entity.endTime),
      estimatedDurationMinutes: Value(entity.estimatedDurationMinutes), // NEW
      isRecurring: Value(entity.isRecurring),
      recurrenceRule: Value(entity.recurrenceRule),
      parentTaskId: Value(entity.parentTaskId),
      reminderLeadMinutes: Value(entity.reminderLeadMinutes),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
    );
  }

  @override
  Stream<Either<Failure, List<TaskEntity>>> watchAllTasks() {
    return _datasource.watchAllTasks().map(
          (models) => Right<Failure, List<TaskEntity>>(models.map(_toEntity).toList()),
    ).handleError((error) {
      return const Left<Failure, List<TaskEntity>>(DatabaseFailure('Failed to load tasks'));
    });
  }

  @override
  Future<Either<Failure, void>> addTask(TaskEntity task) async {
    try {
      await _datasource.insertTask(_toCompanion(task));
      return const Right(null);
    } catch (e) {
      return const Left(DatabaseFailure('Failed to add task'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTask(TaskEntity task) async {
    try {
      await _datasource.updateTask(_toCompanion(task));
      return const Right(null);
    } catch (e) {
      return const Left(DatabaseFailure('Failed to update task'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String id) async {
    try {
      await _datasource.deleteTask(id);
      return const Right(null);
    } catch (e) {
      return const Left(DatabaseFailure('Failed to delete task'));
    }
  }

  @override
  Future<Either<Failure, void>> markOverdueTasks() async {
    try {
      await _datasource.markOverdueTasks();
      return const Right(null);
    } catch (e) {
      return const Left(DatabaseFailure('Failed to mark overdue tasks'));
    }
  }
}