import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/enums/task_status.dart';

abstract class TaskLocalDatasource {
  Stream<List<Task>> watchAllTasks();
  Future<void> insertTask(TasksCompanion companion);
  Future<void> updateTask(TasksCompanion companion);
  Future<void> deleteTask(String id);
  // NEW: Method to find and mark overdue tasks
  Future<void> markOverdueTasks();
}

@LazySingleton(as: TaskLocalDatasource)
class TaskLocalDatasourceImpl implements TaskLocalDatasource {
  final AppDatabase _db;

  TaskLocalDatasourceImpl(this._db);

  @override
  Stream<List<Task>> watchAllTasks() {
    return _db.select(_db.tasks).watch();
  }

  @override
  Future<void> insertTask(TasksCompanion companion) {
    return _db.into(_db.tasks).insert(companion);
  }

  @override
  Future<void> updateTask(TasksCompanion companion) {
    return _db.update(_db.tasks).replace(companion);
  }

  @override
  Future<void> deleteTask(String id) {
    return (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }

  // NEW: The actual database command that updates everything instantly
  @override
  Future<void> markOverdueTasks() async {
    final now = DateTime.now();

    await (_db.update(_db.tasks)
      ..where((t) => t.deadline.isSmallerThanValue(now))
      ..where((t) => t.status.equals(TaskStatus.pending.name)))
        .write(
      TasksCompanion(
        status: const Value(TaskStatus.overdue),
        updatedAt: Value(now),
      ),
    );
  }
}