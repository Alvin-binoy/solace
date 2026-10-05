import 'package:flutter/material.dart';
import '../../daily_schedule_page.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 40, // COMPACT: Reduces the empty space above tabs
          title: const Text('Schedule', style: TextStyle(fontSize: 25)),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            dividerColor: Colors.transparent, // Removes standard thick underline
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