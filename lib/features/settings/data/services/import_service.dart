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
    // 1. Decrypt & Unzip (Throws instantly if password/file is invalid)
    final decryptedBytes = _encryptionService.decryptData(encryptedBytes, password);
    final archive = ZipDecoder().decodeBytes(decryptedBytes);

    String? manifestJson, tasksJson, journalJson, settingsJson, profilesJson;

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

    // 2. Parse JSON (Throws before wiping if data is corrupt)
    final tasks = (jsonDecode(tasksJson) as List).map((e) => Task.fromJson(e)).toList();
    final journalEntries = (jsonDecode(journalJson) as List).map((e) => JournalEntry.fromJson(e)).toList();
    final settings = (jsonDecode(settingsJson) as List).map((e) => AppSetting.fromJson(e)).toList();
    var profiles = profilesJson != null
        ? (jsonDecode(profilesJson) as List).map((e) => UserProfile.fromJson(e)).toList()
        : <UserProfile>[];

    // --- SECURITY PATCH ---
    // Grab current profile to prevent biometrics toggle from downgrading
    final currentProfiles = await _db.select(_db.userProfiles).get();
    if (currentProfiles.isNotEmpty && profiles.isNotEmpty) {
      profiles = profiles.map((incomingProfile) {
        // Find matching profile, fallback to first if IDs don't match
        final current = currentProfiles.where((c) => c.id == incomingProfile.id).firstOrNull ?? currentProfiles.first;
        // Inject current security state into the incoming backup
        return incomingProfile.copyWith(biometricsEnabled: current.biometricsEnabled);
      }).toList();
    }

    // 3. The "Wipe Before Verify" protection is already perfect here!
    // Because it's inside a transaction, if anything above failed, this never runs.
    await _db.transaction(() async {
      await _db.delete(_db.tasks).go();
      await _db.delete(_db.journalEntries).go();
      await _db.delete(_db.appSettings).go();
      await _db.delete(_db.userProfiles).go();

      await _db.batch((batch) {
        batch.insertAll(_db.tasks, tasks);
        batch.insertAll(_db.journalEntries, journalEntries);
        batch.insertAll(_db.appSettings, settings);
        batch.insertAll(_db.userProfiles, profiles);
      });
    });
  }
}