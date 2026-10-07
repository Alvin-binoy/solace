import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/settings_repository.dart';

@injectable
class RestoreBackupUseCase {
  final SettingsRepository _repository;

  RestoreBackupUseCase(this._repository);

  Future<Either<Failure, void>> call(Uint8List backupBytes, String password) {
    return _repository.restoreBackup(backupBytes, password);
  }
}