import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import '../../features/tasks/data/models/task_table.dart';
import '../../features/auth/data/models/user_profile_table.dart';
import '../../features/journal/data/models/journal_entry_table.dart';
import '../../features/settings/data/models/app_settings_table.dart';
import '../enums/task_priority.dart';
import '../enums/task_category.dart';
import '../enums/task_status.dart';
import '../enums/mood.dart';

part 'app_database.g.dart';

@LazySingleton()
@DriftDatabase(tables: [Tasks, UserProfiles, JournalEntries, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4; // Bumped to 4 for userOverridePriority

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 4) {
          // Safely add the new column to existing databases without losing data
          try {
            await m.addColumn(tasks, tasks.userOverridePriority);
          } catch(e) {
            // Ignore if column already exists due to hot restarts
          }
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'solace.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}