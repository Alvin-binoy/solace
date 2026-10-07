import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:drift/drift.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/app_settings_dao.dart';
import '../../domain/entities/app_settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';

@Injectable(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  final AppSettingsDao _dao;
  final ExportService _exportService;
  final ImportService _importService;

  SettingsRepositoryImpl(this._dao, this._exportService, this._importService);

  AppSettingsEntity _toEntity(AppSetting model) {
    return AppSettingsEntity(
      themeMode: model.themeMode,
      accentColorHex: model.accentColorHex,
      dateFormat: model.dateFormat,
      defaultCategory: model.defaultCategory,
      defaultReminderLeadMinutes: model.defaultReminderLeadMinutes,
      quietHoursEnabled: model.quietHoursEnabled,
      quietHoursStart: model.quietHoursStart,
      quietHoursEnd: model.quietHoursEnd,
    );
  }

  AppSettingsCompanion _toCompanion(AppSettingsEntity entity) {
    return AppSettingsCompanion(
      id: const Value(1),
      themeMode: Value(entity.themeMode),
      accentColorHex: Value(entity.accentColorHex),
      dateFormat: Value(entity.dateFormat),
      defaultCategory: Value(entity.defaultCategory),
      defaultReminderLeadMinutes: Value(entity.defaultReminderLeadMinutes),
      quietHoursEnabled: Value(entity.quietHoursEnabled),
      quietHoursStart: Value(entity.quietHoursStart),
      quietHoursEnd: Value(entity.quietHoursEnd),
    );
  }

  @override
  Stream<Either<Failure, AppSettingsEntity>> watchSettings() async* {
    await _dao.getSettings();
    yield* _dao.watchSettings().map(
          (model) => Right<Failure, AppSettingsEntity>(_toEntity(model)),
    ).handleError((error) {
      return const Left<Failure, AppSettingsEntity>(DatabaseFailure('Failed to load settings.'));
    });
  }

  @override
  Future<Either<Failure, void>> updateSettings(AppSettingsEntity settings) async {
    try {
      await _dao.updateSettings(_toCompanion(settings));
      return const Right(null);
    } catch (e) {
      return const Left(DatabaseFailure('Failed to update settings.'));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> createBackup(String password) async {
    try {
      final bytes = await _exportService.generateEncryptedBackup(password);
      return Right(bytes);
    } catch (e) {
      return const Left(DatabaseFailure('Failed to create backup.'));
    }
  }

  @override
  Future<Either<Failure, void>> restoreBackup(Uint8List backupBytes, String password) async {
    try {
      await _importService.restoreEncryptedBackup(backupBytes, password);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}