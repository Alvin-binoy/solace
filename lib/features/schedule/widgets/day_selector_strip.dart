import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/schedule_bloc.dart';

class DaySelectorStrip extends StatelessWidget {
  const DaySelectorStrip({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine colors based on the current theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    final activeBgColor = isDark ? Colors.white : Colors.black;
    final activeTextColor = isDark ? Colors.black : Colors.white;

    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        final today = DateTime.now();
        final dates = List.generate(31, (index) {
          return today.subtract(const Duration(days: 15)).add(Duration(days: index));
        });

        return SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            controller: ScrollController(initialScrollOffset: 15 * 68.0),
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected = _isSameDay(date, state.selectedDate);

              return GestureDetector(
                onTap: () {
                  context.read<ScheduleBloc>().add(SelectedDateChanged(date));
                },
                child: Container(
                  width: 60,
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
                        _getWeekday(date.weekday).toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? activeTextColor : mutedTextColor,
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
}