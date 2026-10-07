import 'package:flutter/material.dart';
import 'widgets/day_selector_strip.dart';
import 'widgets/time_slot_list.dart';

class DailySchedulePage extends StatelessWidget {
  const DailySchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Removed BlocProvider from here because the parent will provide it
    return const Column(
      children: [
        DaySelectorStrip(),
        Expanded(
          child: TimeSlotList(),
        ),
      ],
    );
  }
}