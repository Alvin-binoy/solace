import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/encryption_service.dart';

@lazySingleton
class ExportService {
  final AppDatabase _db;
  final EncryptionService _encryptionService;

  ExportService(this._db, this._encryptionService);

  Future<Uint8List> generateEncryptedBackup(String password) async {
    // 1. Fetch all data from the database
    final tasks = await _db.select(_db.tasks).get();
    final journalEntries = await _db.select(_db.journalEntries).get();
    final settings = await _db.select(_db.appSettings).get();
    final userProfiles = await _db.select(_db.userProfiles).get();

    // 2. Serialize to JSON
    final manifestJson = jsonEncode({
      'appVersion': '1.0.0',
      'dbVersion': _db.schemaVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'taskCount': tasks.length,
      'journalCount': journalEntries.length,
    });

    final tasksJson = jsonEncode(tasks.map((t) => t.toJson()).toList());
    final journalJson = jsonEncode(journalEntries.map((j) => j.toJson()).toList());
    final settingsJson = jsonEncode(settings.map((s) => s.toJson()).toList());
    final profilesJson = jsonEncode(userProfiles.map((p) => p.toJson()).toList());

    // 3. Create a ZIP archive in memory
    final archive = Archive();
    archive.addFile(ArchiveFile('manifest.json', manifestJson.length, utf8.encode(manifestJson)));
    archive.addFile(ArchiveFile('tasks.json', tasksJson.length, utf8.encode(tasksJson)));
    archive.addFile(ArchiveFile('journal.json', journalJson.length, utf8.encode(journalJson)));
    archive.addFile(ArchiveFile('settings.json', settingsJson.length, utf8.encode(settingsJson)));
    archive.addFile(ArchiveFile('profiles.json', profilesJson.length, utf8.encode(profilesJson)));

    // 4. Encode ZIP to bytes
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    if (zipBytes == null) {
      throw Exception('Failed to encode backup archive');
    }

    // 5. Encrypt the ZIP bytes
    return _encryptionService.encryptData(Uint8List.fromList(zipBytes), password);
  }
}