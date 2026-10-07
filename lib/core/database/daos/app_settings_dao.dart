import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../app_database.dart';
import '../../../features/settings/data/models/app_settings_table.dart';

part 'app_settings_dao.g.dart';

@lazySingleton
@DriftAccessor(tables: [AppSettings])
class AppSettingsDao extends DatabaseAccessor<AppDatabase> with _$AppSettingsDaoMixin {
  AppSettingsDao(super.db);

  // Watch for real-time UI updates
  Stream<AppSetting> watchSettings() {
    // Ensures we always have a row to watch
    return select(appSettings).watch().map((rows) => rows.first);
  }

  // Get current settings (and auto-initialize if empty)
  Future<AppSetting> getSettings() async {
    final query = select(appSettings);
    final result = await query.getSingleOrNull();
    if (result != null) return result;

    // EDGE CASE: If no settings exist yet, create the default row
    await into(appSettings).insert(const AppSettingsCompanion());
    return await query.getSingle();
  }

  // Update existing settings
  Future<bool> updateSettings(AppSettingsCompanion settings) {
    return update(appSettings).replace(settings);
  }
}