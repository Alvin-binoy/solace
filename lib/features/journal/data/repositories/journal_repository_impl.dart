import 'dart:convert';
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:injectable/injectable.dart';
import 'package:drift/drift.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/journal_entry_entity.dart';
import '../../domain/repositories/journal_repository.dart';
import '../datasources/journal_local_datasource.dart';

@Injectable(as: JournalRepository)
class JournalRepositoryImpl implements JournalRepository {
  final JournalLocalDatasource _datasource;

  JournalRepositoryImpl(this._datasource);

  // Maps the Drift database model to our clean Domain entity
  JournalEntryEntity _toEntity(JournalEntry model) {
    List<String> parsedTags = [];

    // EDGE CASE: Safely parse the JSON string into a List<String>.
    // If the database has invalid JSON, we catch it and use an empty list instead of crashing.
    try {
      final decoded = jsonDecode(model.tags);
      if (decoded is List) {
        parsedTags = decoded.map((e) => e.toString()).toList();
      }
    } catch (e) {
      parsedTags = [];
    }

    return JournalEntryEntity(
      id: model.id,
      title: model.title,
      bodyJson: model.bodyJson,
      mood: model.mood,
      tags: parsedTags,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  // Maps our clean Domain entity back into a Drift database companion for saving
  JournalEntriesCompanion _toCompanion(JournalEntryEntity entity) {
    return JournalEntriesCompanion(
      id: Value(entity.id),
      title: Value(entity.title),
      bodyJson: Value(entity.bodyJson),
      mood: Value(entity.mood),
      // Encode the List<String> into a JSON string before saving
      tags: Value(jsonEncode(entity.tags)),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
    );
  }

  @override
  Stream<Either<Failure, List<JournalEntryEntity>>> watchAllEntries() {
    return _datasource.watchAllEntries().map(
          (models) => Right<Failure, List<JournalEntryEntity>>(models.map(_toEntity).toList()),
    ).handleError((error) {
      return const Left<Failure, List<JournalEntryEntity>>(DatabaseFailure('Failed to load journal entries'));
    });
  }

  @override
  Future<Either<Failure, JournalEntryEntity?>> getEntryById(String id) async {
    try {
      final model = await _datasource.getEntryById(id);
      if (model == null) return const Right(null);
      return Right(_toEntity(model));
    } catch (e) {
      return const Left(DatabaseFailure('Failed to fetch the journal entry'));
    }
  }

  @override
  Future<Either<Failure, void>> addEntry(JournalEntryEntity entry) async {
    try {
      await _datasource.insertEntry(_toCompanion(entry));
      return const Right(null);
    } catch (e) {
      return const Left(DatabaseFailure('Failed to save journal entry'));
    }
  }

  @override
  Future<Either<Failure, void>> updateEntry(JournalEntryEntity entry) async {
    try {
      await _datasource.updateEntry(_toCompanion(entry));
      return const Right(null);
    } catch (e) {
      return const Left(DatabaseFailure('Failed to update journal entry'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEntry(String id) async {
    try {
      await _datasource.deleteEntry(id);
      return const Right(null);
    } catch (e) {
      return const Left(DatabaseFailure('Failed to delete journal entry'));
    }
  }
}