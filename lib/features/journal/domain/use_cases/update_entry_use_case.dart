import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/journal_entry_entity.dart';
import '../repositories/journal_repository.dart';

@injectable
class UpdateEntryUseCase {
  final JournalRepository _repository;

  UpdateEntryUseCase(this._repository);

  Future<Either<Failure, void>> call(JournalEntryEntity entry) {
    return _repository.updateEntry(entry);
  }
}