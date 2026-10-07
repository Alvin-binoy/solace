import 'package:drift/drift.dart';
import '../../../../core/enums/task_category.dart';

class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Appearance
  TextColumn get themeMode => text().withDefault(const Constant('system'))(); // system | light | dark
  TextColumn get accentColorHex => text().withDefault(const Constant('#9E9E9E'))();
  TextColumn get dateFormat => text().withDefault(const Constant('dd/MM/yyyy'))();

  // Task Defaults
  TextColumn get defaultCategory => textEnum<TaskCategory>().withDefault(const Constant('personal'))();
  IntColumn get defaultReminderLeadMinutes => integer().withDefault(const Constant(30))();

  // Notification Settings
  BoolColumn get quietHoursEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get quietHoursStart => text().withDefault(const Constant('22:00'))();
  TextColumn get quietHoursEnd => text().withDefault(const Constant('07:00'))();
}