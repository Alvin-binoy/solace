import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/schedule_bloc.dart';
import 'widgets/day_selector_strip.dart';
import 'widgets/time_slot_list.dart';

class DailySchedulePage extends StatelessWidget {
  const DailySchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    // We provide the ScheduleBloc here so both the strip and the list share the same state
    return BlocProvider(
      create: (context) => ScheduleBloc(),
      child: const Column(
        children: [
          DaySelectorStrip(),
          Expanded(
            child: TimeSlotList(),
          ),
        ],
      ),
    );
  }
}