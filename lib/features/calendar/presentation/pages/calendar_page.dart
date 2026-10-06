import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/enums/task_status.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/widgets/task_card.dart';
import '../../../tasks/presentation/widgets/task_input_bottom_sheet.dart';
import '../../../tasks/presentation/bloc/task_bloc.dart';
import '../../../tasks/presentation/bloc/task_event.dart';

import '../../../journal/domain/entities/journal_entry_entity.dart';
import '../../../journal/presentation/widgets/journal_card.dart';

import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.I<CalendarBloc>()..add(InitializeCalendar()),
      child: const _CalendarView(),
    );
  }
}

class _CalendarView extends StatefulWidget {
  const _CalendarView();

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  DateTime _focusedDay = DateTime.now();

  // Normalize helper to match BLoC exactly
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<CalendarBloc, CalendarState>(
        builder: (context, state) {
          if (state is CalendarLoading || state is CalendarInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CalendarError) {
            return Center(
              child: Text(
                  state.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)
              ),
            );
          }

          if (state is CalendarLoaded) {
            return Column(
              children: [
                // 1. The Month Calendar
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  currentDay: DateTime.now(),
                  selectedDayPredicate: (day) => isSameDay(state.selectedDate, day),

                  // Disable week/month format toggle to keep it clean
                  availableCalendarFormats: const { CalendarFormat.month: 'Month' },

                  // Link the BLoC event lists to the calendar dots
                  eventLoader: (day) {
                    final normalized = _normalizeDate(day);
                    final tasks = state.taskMap[normalized] ?? [];
                    final journals = state.journalMap[normalized] ?? [];
                    return [...tasks, ...journals];
                  },

                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                    context.read<CalendarBloc>().add(SelectDay(selectedDay));
                  },

                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },

                  // Styling the Calendar
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.onSurface),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  calendarStyle: CalendarStyle(
                    // NEW: Forces the text inside the circle to invert its color so it's always readable
                    selectedTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontWeight: FontWeight.bold,
                    ),
                    todayTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontWeight: FontWeight.bold,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                  ),

                  // Custom Marker Builder for Tasks (Blue/Primary) and Journals (Purple)
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return const SizedBox();

                      bool hasTasks = false;
                      bool hasJournals = false;

                      for (var event in events) {
                        if (event is TaskEntity) hasTasks = true;
                        if (event is JournalEntryEntity) hasJournals = true;
                      }

                      return Positioned(
                        bottom: 6,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasTasks)
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.primary, // Primary color for tasks
                                ),
                              ),
                            if (hasJournals)
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.purple, // Purple for journals
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),
                Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300, height: 1),

                // 2. The Event List for the Selected Day
                Expanded(
                  child: state.selectedDayEvents.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No events scheduled',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    itemCount: state.selectedDayEvents.length,
                    itemBuilder: (context, index) {
                      final event = state.selectedDayEvents[index];

                      // Render Task
                      if (event is TaskEntity) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: TaskCard(
                            task: event,
                            onStatusChanged: (val) {
                              // Quick status toggle directly from calendar
                              final newStatus = (val == true) ? TaskStatus.completed : TaskStatus.pending;
                              // Note: to update tasks from calendar we need the TaskBloc.
                              // We injected it globally in main, so GetIt.I<TaskBloc>() works safely here.
                              GetIt.I<TaskBloc>().add(UpdateTaskEvent(event.copyWith(status: newStatus)));
                            },
                            onTap: () => TaskInputBottomSheet.show(context, existingTask: event),
                          ),
                        );
                      }

                      // Render Journal Entry
                      if (event is JournalEntryEntity) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: JournalCard(
                            entry: event,
                            onTap: () {
                              context.push('/journal-view/${event.id}');
                            },
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}