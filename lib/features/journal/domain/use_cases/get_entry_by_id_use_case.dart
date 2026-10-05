import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/journal_entry_entity.dart';
import '../repositories/journal_repository.dart';

@injectable
class GetEntryByIdUseCase {
  final JournalRepository _repository;

  GetEntryByIdUseCase(this._repository);

  Future<Either<Failure, JournalEntryEntity?>> call(String id) {
    return _repository.getEntryById(id);
  }
}