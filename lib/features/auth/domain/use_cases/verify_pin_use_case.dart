import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

@injectable
class VerifyPinUseCase {
  final AuthRepository _repository;

  VerifyPinUseCase(this._repository);

  Future<Either<Failure, bool>> call(String pin) {
    return _repository.verifyPin(pin);
  }
}