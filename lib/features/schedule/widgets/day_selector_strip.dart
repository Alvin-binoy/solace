import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/schedule_bloc.dart';

class DaySelectorStrip extends StatelessWidget {
  const DaySelectorStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    final activeBgColor = isDark ? Colors.white : Colors.black;
    final activeTextColor = isDark ? Colors.black : Colors.white;

    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        final today = DateTime.now();

        // NEW: Create a 2-year window (365 days in the past, 365 in the future)
        const int pastDays = 365;
        const int futureDays = 365;
        const int totalDays = pastDays + futureDays;

        final selectedMonth = _getMonthName(state.selectedDate.month);
        final selectedYear = state.selectedDate.year;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 4.0),
              child: Text(
                '$selectedMonth $selectedYear',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                // NEW: Calculate the starting scroll offset so "Today" appears on the left side of the screen
                // Each standard item is 68px wide (60 width + 8 horizontal margin)
                controller: ScrollController(initialScrollOffset: (pastDays - 0.5) * 68.0),
                itemCount: totalDays,
                itemBuilder: (context, index) {
                  // NEW: Calculate the date relative to our 365-day past offset
                  final date = today.subtract(const Duration(days: pastDays)).add(Duration(days: index));

                  final isSelected = _isSameDay(date, state.selectedDate);
                  final isToday = _isSameDay(date, today);
                  final dayLabel = isToday ? 'TODAY' : _getWeekday(date.weekday).toUpperCase();

                  // FIX: Ensure 'TODAY' uses a highly visible text color in both dark and light modes
                  Color labelColor;
                  if (isSelected) {
                    labelColor = activeTextColor;
                  } else if (isToday) {
                    labelColor = textColor; // Swapped from primaryColor to guarantee visibility
                  } else {
                    labelColor = mutedTextColor;
                  }

                  return GestureDetector(
                    onTap: () {
                      context.read<ScheduleBloc>().add(SelectedDateChanged(date));
                    },
                    child: Container(
                      width: isToday ? 68 : 60,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? activeBgColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected ? null : Border.all(color: mutedTextColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayLabel,
                            style: TextStyle(
                              color: labelColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isSelected ? activeTextColor : textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getWeekday(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}