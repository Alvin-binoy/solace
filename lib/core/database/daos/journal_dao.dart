import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../app_database.dart';
import '../../../features/journal/data/models/journal_entry_table.dart';

part 'journal_dao.g.dart';

@lazySingleton
@DriftAccessor(tables: [JournalEntries])
class JournalDao extends DatabaseAccessor<AppDatabase> with _$JournalDaoMixin {
  JournalDao(super.db);

  // Watches all entries ordered by creation date (newest first)
  Stream<List<JournalEntry>> watchAllEntries() {
    return (select(journalEntries)
      ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
      ]))
        .watch();
  }

  // Gets a specific entry by its ID
  Future<JournalEntry?> getEntryById(String id) {
    return (select(journalEntries)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // Inserts a new entry into the database
  Future<int> insertEntry(JournalEntriesCompanion entry) {
    return into(journalEntries).insert(entry);
  }

  // Updates an existing entry
  Future<bool> updateEntry(JournalEntriesCompanion entry) {
    return update(journalEntries).replace(entry);
  }

  // Deletes an entry by its ID
  Future<int> deleteEntry(String id) {
    return (delete(journalEntries)..where((t) => t.id.equals(id))).go();
  }
}