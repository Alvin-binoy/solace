import 'package:flutter/material.dart';
// If you placed daily_schedule_page.dart directly in lib/features/schedule/, use this import:
import '../../daily_schedule_page.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Schedule'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Daily'),
              Tab(text: 'Weekly'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // This now loads your new timeline UI!
            DailySchedulePage(),

            // Weekly view placeholder
            Center(
              child: Text(
                'Weekly View\n(Coming in Stage 7)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}