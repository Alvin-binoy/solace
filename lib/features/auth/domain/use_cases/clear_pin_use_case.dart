import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

@injectable
class ClearPinUseCase {
  final AuthRepository _repository;

  ClearPinUseCase(this._repository);

  Future<Either<Failure, void>> call() {
    return _repository.clearPin();
  }
}