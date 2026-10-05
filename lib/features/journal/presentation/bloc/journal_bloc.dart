import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/journal_entry_entity.dart';
import '../../domain/use_cases/add_entry_use_case.dart';
import '../../domain/use_cases/delete_entry_use_case.dart';
import '../../domain/use_cases/update_entry_use_case.dart';
import '../../domain/use_cases/watch_all_entries_use_case.dart';
import 'journal_event.dart';
import 'journal_state.dart';

@injectable
class JournalBloc extends Bloc<JournalEvent, JournalState> {
  final WatchAllEntriesUseCase _watchAllEntries;
  final AddEntryUseCase _addEntry;
  final UpdateEntryUseCase _updateEntry;
  final DeleteEntryUseCase _deleteEntry;

  JournalBloc(
      this._watchAllEntries,
      this._addEntry,
      this._updateEntry,
      this._deleteEntry,
      ) : super(JournalInitial()) {
    on<WatchEntriesEvent>(_onWatchEntries);
    on<AddEntryEvent>(_onAddEntry);
    on<UpdateEntryEvent>(_onUpdateEntry);
    on<DeleteEntryEvent>(_onDeleteEntry);
  }

  Future<void> _onWatchEntries(WatchEntriesEvent event, Emitter<JournalState> emit) async {
    emit(JournalLoading());

    await emit.forEach<Either<Failure, List<JournalEntryEntity>>>(
      _watchAllEntries(),
      onData: (result) => result.fold(
            (failure) => JournalError(failure.message),
            (entries) => JournalLoaded(entries),
      ),
      // EDGE CASE: Catch any unexpected stream errors to prevent a crash
      onError: (_, __) => const JournalError('An unexpected error occurred loading journal entries.'),
    );
  }

  Future<void> _onAddEntry(AddEntryEvent event, Emitter<JournalState> emit) async {
    await _addEntry(event.entry);
  }

  Future<void> _onUpdateEntry(UpdateEntryEvent event, Emitter<JournalState> emit) async {
    await _updateEntry(event.entry);
  }

  Future<void> _onDeleteEntry(DeleteEntryEvent event, Emitter<JournalState> emit) async {
    await _deleteEntry(event.id);
  }
}