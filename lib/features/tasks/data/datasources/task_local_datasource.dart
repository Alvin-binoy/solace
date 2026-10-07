import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/enums/task_status.dart';

abstract class TaskLocalDatasource {
  Stream<List<Task>> watchAllTasks();
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
    // EDGE CASE SOLVED: Get exactly 00:00:00 of today's date
    final startOfToday = DateTime(now.year, now.month, now.day);

    await (_db.update(_db.tasks)
      ..where((t) => t.status.equals(TaskStatus.pending.name))
      ..where((t) =>
      // 1. If it has an exact end time, check if that exact time has passed
      (t.endTime.isNotNull() & t.endTime.isSmallerThanValue(now)) |
      // 2. If it ONLY has a date, check if midnight of today has passed (meaning it is yesterday or older)
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