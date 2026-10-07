import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/enums/task_status.dart';
import '../tasks/presentation/bloc/task_bloc.dart';
import '../tasks/presentation/bloc/task_state.dart';
import '../tasks/presentation/bloc/task_event.dart';
import '../tasks/presentation/widgets/task_card.dart';
import '../tasks/presentation/widgets/task_input_bottom_sheet.dart';

import 'bloc/schedule_bloc.dart';
import 'widgets/day_selector_strip.dart';
import 'widgets/time_slot_list.dart';

class DailySchedulePage extends StatelessWidget {
  const DailySchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DaySelectorStrip(),

        // NEW: Collapsible Unscheduled Tasks Section
        BlocBuilder<ScheduleBloc, ScheduleState>(
            builder: (context, scheduleState) {
              return BlocBuilder<TaskBloc, TaskState>(
                builder: (context, taskState) {
                  if (taskState is TaskLoaded) {
                    final unscheduledTasks = taskState.tasks.where((task) {
                      final date = task.scheduledAt ?? task.deadline;
                      if (date == null) return false;
                      if (task.startTime != null) return false;

                      return date.year == scheduleState.selectedDate.year &&
                          date.month == scheduleState.selectedDate.month &&
                          date.day == scheduleState.selectedDate.day;
                    }).toList();

                    if (unscheduledTasks.isEmpty) return const SizedBox.shrink();

                    return Theme(
                      // Removes the default borders Flutter adds to ExpansionTiles
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: true, // Open by default
                        tilePadding: const EdgeInsets.symmetric(horizontal: 20.0),
                        title: Text(
                          'UNSCHEDULED (${unscheduledTasks.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        children: [
                          Container(
                            // Keeps it from pushing the timeline off-screen
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              shrinkWrap: true,
                              itemCount: unscheduledTasks.length,
                              itemBuilder: (context, index) {
                                final task = unscheduledTasks[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: TaskCard(
                                    task: task,
                                    onStatusChanged: (val) {
                                      final newStatus = (val == true) ? TaskStatus.completed : TaskStatus.pending;
                                      context.read<TaskBloc>().add(UpdateTaskEvent(task.copyWith(status: newStatus)));
                                    },
                                    onTap: () => TaskInputBottomSheet.show(context, existingTask: task),
                                  ),
                                );
                              },
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            }
        ),

        // The Hourly Timeline
        const Expanded(
          child: TimeSlotList(),
        ),
      ],
    );
  }
}