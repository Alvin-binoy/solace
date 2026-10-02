import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/task_repository.dart';

@injectable
class DeleteTaskUseCase {
  final TaskRepository _repository;

  DeleteTaskUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) {
    return _repository.deleteTask(id);
  }
}