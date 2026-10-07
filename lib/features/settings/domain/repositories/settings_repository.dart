import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_settings_entity.dart';

abstract class SettingsRepository {
  Stream<Either<Failure, AppSettingsEntity>> watchSettings();
  Future<Either<Failure, void>> updateSettings(AppSettingsEntity settings);

  // NEW: Backup and Restore operations
  Future<Either<Failure, Uint8List>> createBackup(String password);
  Future<Either<Failure, void>> restoreBackup(Uint8List backupBytes, String password);
}