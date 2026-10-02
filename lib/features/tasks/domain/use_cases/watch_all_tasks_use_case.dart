import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

@injectable
class WatchAllTasksUseCase {
  final TaskRepository _repository;

  WatchAllTasksUseCase(this._repository);

  Stream<Either<Failure, List<TaskEntity>>> call() {
    return _repository.watchAllTasks();
  }
}