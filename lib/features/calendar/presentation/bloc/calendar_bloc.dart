import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/domain/use_cases/watch_all_tasks_use_case.dart';
import '../../../journal/domain/entities/journal_entry_entity.dart';
import '../../../journal/domain/use_cases/watch_all_entries_use_case.dart';
import 'calendar_event.dart';
import 'calendar_state.dart';

@injectable
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final WatchAllTasksUseCase _watchAllTasks;
  final WatchAllEntriesUseCase _watchAllEntries;

  Map<DateTime, List<TaskEntity>> _currentTaskMap = {};
  Map<DateTime, List<JournalEntryEntity>> _currentJournalMap = {};

  CalendarBloc(this._watchAllTasks, this._watchAllEntries) : super(CalendarInitial()) {
    on<InitializeCalendar>(_onInitialize);
    on<SelectDay>(_onSelectDay);
  }

  // Safely strips hours/minutes to group events accurately by day
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _onInitialize(InitializeCalendar event, Emitter<CalendarState> emit) async {
    emit(CalendarLoading());

    // Combine both streams into one reactive pipeline
    final combinedStream = Rx.combineLatest2(
      _watchAllTasks(),
      _watchAllEntries(),
          (Either<Failure, List<TaskEntity>> tasksResult, Either<Failure, List<JournalEntryEntity>> journalsResult) {
        return {'tasks': tasksResult, 'journals': journalsResult};
      },
    );

    await emit.forEach(
      combinedStream,
      onData: (Map<String, dynamic> data) {
        final tasksResult = data['tasks'] as Either<Failure, List<TaskEntity>>;
        final journalsResult = data['journals'] as Either<Failure, List<JournalEntryEntity>>;

        if (tasksResult.isLeft() || journalsResult.isLeft()) {
          return const CalendarError('Failed to load calendar data.');
        }

        final tasks = tasksResult.getOrElse((_) => []);
        final journals = journalsResult.getOrElse((_) => []);

        _currentTaskMap = {};
        for (var task in tasks) {
          // Check all possible date fields to place it on the calendar
          final dateToUse = task.deadline ?? task.scheduledAt ?? task.startTime;
          if (dateToUse != null) {
            final normalized = _normalizeDate(dateToUse);
            _currentTaskMap.putIfAbsent(normalized, () => []).add(task);
          }
        }

        _currentJournalMap = {};
        for (var journal in journals) {
          final normalized = _normalizeDate(journal.createdAt);
          _currentJournalMap.putIfAbsent(normalized, () => []).add(journal);
        }

        // Retain the currently selected date, default to today
        DateTime targetDate = DateTime.now();
        if (state is CalendarLoaded) {
          targetDate = (state as CalendarLoaded).selectedDate;
        }

        final normalizedTarget = _normalizeDate(targetDate);
        final selectedEvents = [
          ...?_currentTaskMap[normalizedTarget],
          ...?_currentJournalMap[normalizedTarget],
        ];

        return CalendarLoaded(
          taskMap: _currentTaskMap,
          journalMap: _currentJournalMap,
          selectedDate: targetDate,
          selectedDayEvents: selectedEvents,
        );
      },
      onError: (_, __) => const CalendarError('An unexpected error occurred loading the calendar.'),
    );
  }

  void _onSelectDay(SelectDay event, Emitter<CalendarState> emit) {
    if (state is CalendarLoaded) {
      final normalizedTarget = _normalizeDate(event.selectedDay);
      final selectedEvents = [
        ...?_currentTaskMap[normalizedTarget],
        ...?_currentJournalMap[normalizedTarget],
      ];

      emit(CalendarLoaded(
        taskMap: _currentTaskMap,
        journalMap: _currentJournalMap,
        selectedDate: event.selectedDay,
        selectedDayEvents: selectedEvents,
      ));
    }
  }
}