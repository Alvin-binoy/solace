import 'package:equatable/equatable.dart';
import '../../domain/entities/journal_entry_entity.dart';

sealed class JournalState extends Equatable {
  const JournalState();
  @override
  List<Object> get props => [];
}

class JournalInitial extends JournalState {}

class JournalLoading extends JournalState {}

class JournalLoaded extends JournalState {
  final List<JournalEntryEntity> entries;

  const JournalLoaded(this.entries);

  @override
  List<Object> get props => [entries];
}

class JournalError extends JournalState {
  final String message;

  const JournalError(this.message);

  @override
  List<Object> get props => [message];
}