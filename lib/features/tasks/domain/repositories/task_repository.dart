import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/task_entity.dart';

abstract class TaskRepository {
  // Returns a stream so the UI updates instantly when a task changes!
  Stream<Either<Failure, List<TaskEntity>>> watchAllTasks();

  Future<Either<Failure, void>> addTask(TaskEntity task);
  Future<Either<Failure, void>> updateTask(TaskEntity task);
  Future<Either<Failure, void>> deleteTask(String id);
}