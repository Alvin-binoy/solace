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
              // COMPACT: Stripped out the 12px top padding
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 0.0),
              child: Text(
                '$selectedMonth $selectedYear',
                style: TextStyle(
                  fontSize: 16, // COMPACT: Shrunk slightly to fit tighter
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(
              height: 64, // COMPACT: Reduced container height from 80 to 64
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                controller: ScrollController(initialScrollOffset: (pastDays - 0.5) * 68.0),
                itemCount: totalDays,
                itemBuilder: (context, index) {
                  final date = today.subtract(const Duration(days: pastDays)).add(Duration(days: index));
                  final isSelected = _isSameDay(date, state.selectedDate);
                  final isToday = _isSameDay(date, today);
                  final dayLabel = isToday ? 'TODAY' : _getWeekday(date.weekday).toUpperCase();

                  Color labelColor;
                  if (isSelected) {
                    labelColor = activeTextColor;
                  } else if (isToday) {
                    labelColor = textColor;
                  } else {
                    labelColor = mutedTextColor;
                  }

                  return GestureDetector(
                    onTap: () {
                      context.read<ScheduleBloc>().add(SelectedDateChanged(date));
                    },
                    child: Container(
                      width: isToday ? 68 : 60,
                      // COMPACT: Smashed the vertical margin down from 8 to 4
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                          const SizedBox(height: 2), // COMPACT: Reduced from 4
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isSelected ? activeTextColor : textColor,
                              fontSize: 18, // COMPACT: Reduced from 20
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