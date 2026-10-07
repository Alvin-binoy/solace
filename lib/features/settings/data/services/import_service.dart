import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/encryption_service.dart';

@lazySingleton
class ImportService {
  final AppDatabase _db;
  final EncryptionService _encryptionService;

  ImportService(this._db, this._encryptionService);

  Future<void> restoreEncryptedBackup(Uint8List encryptedBytes, String password) async {
    // 1. Decrypt the bytes
    final decryptedBytes = _encryptionService.decryptData(encryptedBytes, password);

    // 2. Unzip the archive
    final archive = ZipDecoder().decodeBytes(decryptedBytes);

    String? manifestJson;
    String? tasksJson;
    String? journalJson;
    String? settingsJson;
    String? profilesJson;

    // 3. Extract the JSON strings
    for (final file in archive) {
      if (file.isFile) {
        final content = utf8.decode(file.content as List<int>);
        switch (file.name) {
          case 'manifest.json': manifestJson = content; break;
          case 'tasks.json': tasksJson = content; break;
          case 'journal.json': journalJson = content; break;
          case 'settings.json': settingsJson = content; break;
          case 'profiles.json': profilesJson = content; break;
        }
      }
    }

    if (manifestJson == null || tasksJson == null || journalJson == null || settingsJson == null) {
      throw Exception('Invalid backup file format: Missing required data files.');
    }

    // 4. Deserialize Drift Models
    final tasks = (jsonDecode(tasksJson) as List).map((e) => Task.fromJson(e)).toList();
    final journalEntries = (jsonDecode(journalJson) as List).map((e) => JournalEntry.fromJson(e)).toList();
    final settings = (jsonDecode(settingsJson) as List).map((e) => AppSetting.fromJson(e)).toList();
    final profiles = profilesJson != null
        ? (jsonDecode(profilesJson) as List).map((e) => UserProfile.fromJson(e)).toList()
        : <UserProfile>[];

    // 5. Safely replace the entire database in a transaction
    await _db.transaction(() async {
      // Clear existing
      await _db.delete(_db.tasks).go();
      await _db.delete(_db.journalEntries).go();
      await _db.delete(_db.appSettings).go();
      await _db.delete(_db.userProfiles).go();

      // Insert backup data
      await _db.batch((batch) {
        batch.insertAll(_db.tasks, tasks);
        batch.insertAll(_db.journalEntries, journalEntries);
        batch.insertAll(_db.appSettings, settings);
        batch.insertAll(_db.userProfiles, profiles);
      });
    });
  }
}