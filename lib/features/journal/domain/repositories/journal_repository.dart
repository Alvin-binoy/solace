import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/journal_entry_entity.dart';

abstract class JournalRepository {
  // Returns a stream so the UI updates instantly when any journal entry changes
  Stream<Either<Failure, List<JournalEntryEntity>>> watchAllEntries();

  // EDGE CASE: Returns JournalEntryEntity? (nullable) in case the ID does not exist
  Future<Either<Failure, JournalEntryEntity?>> getEntryById(String id);

  Future<Either<Failure, void>> addEntry(JournalEntryEntity entry);

  Future<Either<Failure, void>> updateEntry(JournalEntryEntity entry);

  Future<Either<Failure, void>> deleteEntry(String id);
}