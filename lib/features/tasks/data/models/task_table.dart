import 'package:drift/drift.dart';
import '../../../../core/enums/task_category.dart';
import '../../../../core/enums/task_priority.dart';
import '../../../../core/enums/task_status.dart';

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  TextColumn get priority => textEnum<TaskPriority>()();
  TextColumn get category => textEnum<TaskCategory>()();
  TextColumn get status => textEnum<TaskStatus>()();

  DateTimeColumn get scheduledAt => dateTime().nullable()();
  DateTimeColumn get startTime => dateTime().nullable()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get estimatedDurationMinutes => integer().nullable()();
  DateTimeColumn get deadline => dateTime().nullable()();

  // NEW: User Override Flag!
  BoolColumn get userOverridePriority => boolean().withDefault(const Constant(false))();

  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurrenceRule => text().nullable()();
  TextColumn get parentTaskId => text().nullable()();
  IntColumn get reminderLeadMinutes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}