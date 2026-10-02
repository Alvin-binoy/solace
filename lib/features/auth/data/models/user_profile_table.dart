import 'package:drift/drift.dart';

class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get displayName => text()();
  TextColumn get avatarPath => text().nullable()();
  BoolColumn get biometricsEnabled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}
