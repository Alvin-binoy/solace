import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/journal_entry_entity.dart';
import '../repositories/journal_repository.dart';

@injectable
class WatchAllEntriesUseCase {
  final JournalRepository _repository;

  WatchAllEntriesUseCase(this._repository);

  Stream<Either<Failure, List<JournalEntryEntity>>> call() {
    return _repository.watchAllEntries();
  }
}