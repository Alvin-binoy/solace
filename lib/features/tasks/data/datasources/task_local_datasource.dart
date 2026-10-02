import 'package:injectable/injectable.dart';
import '../../../../core/database/app_database.dart';

abstract class TaskLocalDatasource {
  Stream<List<Task>> watchAllTasks();
  Future<void> insertTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String id);
}

@LazySingleton(as: TaskLocalDatasource)
class TaskLocalDatasourceImpl implements TaskLocalDatasource {
  final AppDatabase _db;

  TaskLocalDatasourceImpl(this._db);

  @override
  Stream<List<Task>> watchAllTasks() {
    // Watches the table and emits a new list instantly whenever data changes!
    return _db.select(_db.tasks).watch();
  }

  @override
  Future<void> insertTask(Task task) {
    return _db.into(_db.tasks).insert(task);
  }

  @override
  Future<void> updateTask(Task task) {
    return _db.update(_db.tasks).replace(task);
  }

  @override
  Future<void> deleteTask(String id) {
    return (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }
}