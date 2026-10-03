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

  // The general date the task is scheduled for (Flexible To-Do)
  DateTimeColumn get scheduledAt => dateTime().nullable()();

  // NEW: Optional time-blocking fields for professional calendar events
  DateTimeColumn get startTime => dateTime().nullable()();
  DateTimeColumn get endTime => dateTime().nullable()();

  DateTimeColumn get deadline => dateTime().nullable()();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurrenceRule => text().nullable()();
  TextColumn get parentTaskId => text().nullable()();
  IntColumn get reminderLeadMinutes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}