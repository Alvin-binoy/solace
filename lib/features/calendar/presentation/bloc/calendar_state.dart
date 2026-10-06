import 'package:equatable/equatable.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../journal/domain/entities/journal_entry_entity.dart';

sealed class CalendarState extends Equatable {
  const CalendarState();
  @override
  List<Object?> get props => [];
}

class CalendarInitial extends CalendarState {}

class CalendarLoading extends CalendarState {}

class CalendarLoaded extends CalendarState {
  final Map<DateTime, List<TaskEntity>> taskMap;
  final Map<DateTime, List<JournalEntryEntity>> journalMap;
  final DateTime selectedDate;
  final List<Object> selectedDayEvents; // Mixed list of Tasks and Journals for the timeline

  const CalendarLoaded({
    required this.taskMap,
    required this.journalMap,
    required this.selectedDate,
    required this.selectedDayEvents,
  });

  @override
  List<Object?> get props => [taskMap, journalMap, selectedDate, selectedDayEvents];
}

class CalendarError extends CalendarState {
  final String message;
  const CalendarError(this.message);
  @override
  List<Object> get props => [message];
}