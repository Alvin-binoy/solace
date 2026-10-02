import 'package:injectable/injectable.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';

@lazySingleton
class OverdueCheckerService {
  final TaskRepository _repository;

  OverdueCheckerService(this._repository);

  /// Runs the database check to instantly mark missed tasks as overdue.
  Future<void> checkNow() async {
    // This calls the method we just added to the repository
    await _repository.markOverdueTasks();
  }
}