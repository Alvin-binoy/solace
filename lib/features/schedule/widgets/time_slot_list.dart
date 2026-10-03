import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/schedule_bloc.dart';

class TimeSlotList extends StatelessWidget {
  const TimeSlotList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        // In the future, we will filter the task stream based on state.selectedDate
        // For now, we are building the 24-hour visual framework.

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: 24, // 24 hours in a day
          itemBuilder: (context, index) {
            final hour = index;
            final isCurrentHour = _isCurrentHour(state.selectedDate, hour);

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Time Label
                  SizedBox(
                    width: 70,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, right: 12),
                      child: Text(
                        _formatHour(hour),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: isCurrentHour
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade600,
                          fontWeight: isCurrentHour ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),

                  // Timeline Divider
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        width: 2,
                        color: Colors.grey.shade300,
                      ),
                      if (isCurrentHour)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  // Task Slot Area
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 60),
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      alignment: Alignment.topLeft,
                      child: Container(
                        height: 45, // Placeholder height for a task card
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100, // Very faint background indicating drop zone
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'No tasks scheduled',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _isCurrentHour(DateTime selectedDate, int hour) {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day &&
        now.hour == hour;
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour > 12) return '${hour - 12} PM';
    return '$hour AM';
  }
}