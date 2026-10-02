import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

@injectable
class SetupPinUseCase {
  final AuthRepository _repository;

  SetupPinUseCase(this._repository);

  // The 'call' method lets us use this class like a regular function
  Future<Either<Failure, void>> call(String pin) {
    return _repository.setupPin(pin);
  }
}