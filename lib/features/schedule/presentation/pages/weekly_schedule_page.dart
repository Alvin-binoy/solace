import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/bloc/task_bloc.dart';
import '../../../tasks/presentation/bloc/task_state.dart';
// FIXED: Corrected the relative path to your ScheduleBloc
import '../../bloc/schedule_bloc.dart';

class WeeklySchedulePage extends StatefulWidget {
  const WeeklySchedulePage({super.key});

  @override
  State<WeeklySchedulePage> createState() => _WeeklySchedulePageState();
}

class _WeeklySchedulePageState extends State<WeeklySchedulePage> {
  // Using 1000 as a middle starting point so we can swipe infinitely into the past or future
  final int _initialPage = 1000;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Helper to find the Monday of the requested week
  DateTime _getMondayForWeek(int pageIndex) {
    final now = DateTime.now();
    // Find the most recent Monday for the current week
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));
    // Offset by the number of weeks swiped
    final weekOffset = pageIndex - _initialPage;
    return currentMonday.add(Duration(days: weekOffset * 7));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, taskState) {
        List<TaskEntity> allTasks = [];
        if (taskState is TaskLoaded) {
          allTasks = taskState.tasks;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 20.0, top: 24.0, bottom: 8.0),
              child: Text(
                'Swipe for more weeks',
                style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemBuilder: (context, index) {
                  final monday = _getMondayForWeek(index);
                  return _buildWeekGrid(monday, allTasks);
                },
              ),
            ),
            const SizedBox(height: 120), // Padding to clear the floating bottom nav bar
          ],
        );
      },
    );
  }

  Widget _buildWeekGrid(DateTime monday, List<TaskEntity> tasks) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final currentDate = monday.add(Duration(days: index));
          return Expanded(
            child: _buildDayColumn(currentDate, tasks),
          );
        }),
      ),
    );
  }

  Widget _buildDayColumn(DateTime date, List<TaskEntity> tasks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    // Count tasks strictly scheduled for this specific day
    final dayTasks = tasks.where((t) {
      final taskDate = t.startTime ?? t.scheduledAt ?? t.deadline;
      if (taskDate == null) return false;
      return taskDate.year == date.year &&
          taskDate.month == date.month &&
          taskDate.day == date.day;
    }).toList();

    return GestureDetector(
      onTap: () {
        // 1. Update the shared ScheduleBloc with the selected date
        context.read<ScheduleBloc>().add(SelectedDateChanged(date));
        // 2. Magically slide the TabController back to the "Daily" tab (Index 0)
        DefaultTabController.of(context).animateTo(0);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        decoration: BoxDecoration(
          // FIXED: Upgraded to withValues() to handle the deprecation warning
          color: isToday
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isToday
                ? Theme.of(context).colorScheme.primary
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            width: isToday ? 2 : 1.5,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              DateFormat('EEE').format(date).toUpperCase(), // MON, TUE
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isToday ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isToday ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),

            // Task Count Badge at the bottom of the column
            if (dayTasks.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${dayTasks.length}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.surface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.check_circle_outline, color: Colors.grey, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}