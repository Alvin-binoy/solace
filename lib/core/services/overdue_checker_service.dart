import 'dart:async';
import 'package:injectable/injectable.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';

@lazySingleton
class OverdueCheckerService {
  final TaskRepository _repository;
  Timer? _timer;

  OverdueCheckerService(this._repository) {
    // Automatically start the 1-minute ticker when the service is created
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      checkNow();
    });
  }

  /// Runs the database check to instantly mark missed tasks as overdue.
  Future<void> checkNow() async {
    await _repository.markOverdueTasks();
  }

  // Clean up the timer if the service is ever destroyed
  void dispose() {
    _timer?.cancel();
  }
}