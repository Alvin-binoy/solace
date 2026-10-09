import 'dart:async';
import 'package:injectable/injectable.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';
import '../../features/tasks/domain/services/priority_engine.dart'; // NEW IMPORT

@lazySingleton
class OverdueCheckerService {
  final TaskRepository _repository;
  final PriorityEngine _priorityEngine; // NEW: Inject the engine
  Timer? _timer;

  OverdueCheckerService(this._repository, this._priorityEngine) {
    // Automatically start the 1-minute ticker when the service is created
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      checkNow();
    });
  }

  /// Runs the database check to instantly mark missed tasks as overdue,
  /// and runs the smart priority engine.
  Future<void> checkNow() async {
    await _repository.markOverdueTasks();
    await _priorityEngine.execute(); // NEW: Run the engine!
  }

  // Clean up the timer if the service is ever destroyed
  void dispose() {
    _timer?.cancel();
  }
}