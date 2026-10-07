import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/app_settings_entity.dart';
import '../repositories/settings_repository.dart';

@injectable
class UpdateSettingsUseCase {
  final SettingsRepository _repository;

  UpdateSettingsUseCase(this._repository);

  Future<Either<Failure, void>> call(AppSettingsEntity settings) {
    return _repository.updateSettings(settings);
  }
}