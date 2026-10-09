import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/enums/task_status.dart';

abstract class TaskLocalDatasource {
  Stream<List<Task>> watchAllTasks();

  // NEW: A one-time fetch for our background engines
  Future<List<Task>> getPendingTasks();

  Future<void> insertTask(TasksCompanion companion);
  Future<void> updateTask(TasksCompanion companion);
  Future<void> deleteTask(String id);
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

  // NEW: Grabs all tasks that aren't completed or overdue yet
  @override
  Future<List<Task>> getPendingTasks() {
    return (_db.select(_db.tasks)..where((t) => t.status.equals(TaskStatus.pending.name))).get();
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

  @override
  Future<void> markOverdueTasks() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    await (_db.update(_db.tasks)
      ..where((t) => t.status.equals(TaskStatus.pending.name))
      ..where((t) =>
      (t.endTime.isNotNull() & t.endTime.isSmallerThanValue(now)) |
      (t.endTime.isNull() & t.deadline.isNotNull() & t.deadline.isSmallerThanValue(startOfToday))
      ))
        .write(
      TasksCompanion(
        status: const Value(TaskStatus.overdue),
        updatedAt: Value(now),
      ),
    );
  }
}