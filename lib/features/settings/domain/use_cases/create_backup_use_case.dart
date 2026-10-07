import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/settings_repository.dart';

@injectable
class CreateBackupUseCase {
  final SettingsRepository _repository;

  CreateBackupUseCase(this._repository);

  Future<Either<Failure, Uint8List>> call(String password) {
    return _repository.createBackup(password);
  }
}