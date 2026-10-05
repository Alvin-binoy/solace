import 'package:equatable/equatable.dart';
import '../../domain/entities/journal_entry_entity.dart';

sealed class JournalEvent extends Equatable {
  const JournalEvent();
  @override
  List<Object> get props => [];
}

class WatchEntriesEvent extends JournalEvent {}

class AddEntryEvent extends JournalEvent {
  final JournalEntryEntity entry;
  const AddEntryEvent(this.entry);
  @override
  List<Object> get props => [entry];
}

class UpdateEntryEvent extends JournalEvent {
  final JournalEntryEntity entry;
  const UpdateEntryEvent(this.entry);
  @override
  List<Object> get props => [entry];
}

class DeleteEntryEvent extends JournalEvent {
  final String id;
  const DeleteEntryEvent(this.id);
  @override
  List<Object> get props => [id];
}