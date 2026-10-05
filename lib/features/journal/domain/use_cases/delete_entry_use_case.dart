import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/journal_repository.dart';

@injectable
class DeleteEntryUseCase {
  final JournalRepository _repository;

  DeleteEntryUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) {
    return _repository.deleteEntry(id);
  }
}