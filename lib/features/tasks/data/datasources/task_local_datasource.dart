import 'package:injectable/injectable.dart';
import '../../../../core/database/app_database.dart';

// 1. The "Menu" - just lists what this file can do
abstract class TaskLocalDatasource {
  Stream<List<Task>> watchAllTasks();
  Future<void> insertTask(TasksCompanion companion);
  Future<void> updateTask(TasksCompanion companion);
  Future<void> deleteTask(String id);
}

// 2. The "Kitchen" - actually does the work
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
}