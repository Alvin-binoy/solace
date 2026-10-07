import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/app_settings_entity.dart';
import '../repositories/settings_repository.dart';

@injectable
class WatchSettingsUseCase {
  final SettingsRepository _repository;

  WatchSettingsUseCase(this._repository);

  Stream<Either<Failure, AppSettingsEntity>> call() {
    return _repository.watchSettings();
  }
}