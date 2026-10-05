import 'package:injectable/injectable.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/journal_dao.dart';

abstract class JournalLocalDatasource {
  Stream<List<JournalEntry>> watchAllEntries();
  Future<JournalEntry?> getEntryById(String id);
  Future<void> insertEntry(JournalEntriesCompanion companion);
  Future<void> updateEntry(JournalEntriesCompanion companion);
  Future<void> deleteEntry(String id);
}

@LazySingleton(as: JournalLocalDatasource)
class JournalLocalDatasourceImpl implements JournalLocalDatasource {
  final JournalDao _journalDao;

  JournalLocalDatasourceImpl(this._journalDao);

  @override
  Stream<List<JournalEntry>> watchAllEntries() {
    return _journalDao.watchAllEntries();
  }

  @override
  Future<JournalEntry?> getEntryById(String id) {
    return _journalDao.getEntryById(id);
  }

  @override
  Future<void> insertEntry(JournalEntriesCompanion companion) async {
    await _journalDao.insertEntry(companion);
  }

  @override
  Future<void> updateEntry(JournalEntriesCompanion companion) async {
    await _journalDao.updateEntry(companion);
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _journalDao.deleteEntry(id);
  }
}