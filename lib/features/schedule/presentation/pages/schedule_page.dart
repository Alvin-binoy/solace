import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../daily_schedule_page.dart';
import '../../bloc/schedule_bloc.dart';
import 'weekly_schedule_page.dart';
class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the ScheduleBloc at the top level so both tabs share the selected date
    return BlocProvider(
      create: (context) => ScheduleBloc(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 40,
            title: const Text('Schedule', style: TextStyle(fontSize: 25)),
            automaticallyImplyLeading: false,
            bottom: const TabBar(
              dividerColor: Colors.transparent,
              labelPadding: EdgeInsets.zero,
              tabs: [
                Tab(text: 'Daily'),
                Tab(text: 'Weekly'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              DailySchedulePage(),
              WeeklySchedulePage(), // REPLACED THE PLACEHOLDER HERE
            ],
          ),
        ),
      ),
    );
  }
}