import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../main.dart';
import '../widgets/task_input_bottom_sheet.dart';
import '../../../../core/enums/task_status.dart';
import '../../domain/entities/task_entity.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../widgets/task_card.dart';
import '../../../../core/router/main_shell.dart'; // Gives access to globalTabNotifier
import 'task_list_page.dart'; // Gives access to globalTaskFilterNotifier and TaskFilterCategory enum

// NEW IMPORTS
import '../widgets/daily_progress_ring.dart';
import '../widgets/weekly_bar_chart.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DASHBOARD'),
        automaticallyImplyLeading: false,
        actions: [
          StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 30)),
              builder: (context, _) {
                return BlocBuilder<TaskBloc, TaskState>(
                  builder: (context, state) {
                    int activeAlarmsCount = 0;
                    List<TaskEntity> activeAlarmTasks = [];

                    if (state is TaskLoaded) {
                      final now = DateTime.now();
                      activeAlarmTasks = state.tasks.where((t) {
                        if (t.status == TaskStatus.completed || t.reminderLeadMinutes == null || t.startTime == null) {
                          return false;
                        }
                        final ringTime = t.startTime!.subtract(Duration(minutes: t.reminderLeadMinutes!));
                        return ringTime.isAfter(now);
                      }).toList();
                      activeAlarmsCount = activeAlarmTasks.length;
                    }

                    return IconButton(
                      icon: Badge(
                        isLabelVisible: activeAlarmsCount > 0,
                        label: Text(activeAlarmsCount.toString()),
                        child: const Icon(Icons.notifications_outlined),
                      ),
                      tooltip: 'Active Alarms',
                      onPressed: () => _showNotificationCenter(context, activeAlarmTasks),
                    );
                  },
                );
              }
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, _) {
              final isDark = currentMode == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                tooltip: 'Toggle Theme',
                onPressed: () {
                  themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TaskLoading || state is TaskInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TaskError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          } else if (state is TaskLoaded) {

            final activeTasks = state.tasks.where((t) => t.status != TaskStatus.completed).toList();
            final completedTasks = state.tasks.where((t) => t.status == TaskStatus.completed).toList();

            final pendingCount = state.tasks.where((t) => t.status == TaskStatus.pending).length;
            final overdueCount = state.tasks.where((t) => t.status == TaskStatus.overdue).length;

            return ListView(
              padding: const EdgeInsets.only(bottom: 120), // Padding to clear the floating nav bar
              children: [
                // 1. Stat Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      // EDGE CASE FIX: Hooked up the onTap actions to our new Notifiers
                      _StatCard(
                        title: 'Pending',
                        count: pendingCount,
                        onTap: () {
                          globalTaskFilterNotifier.value = TaskFilterCategory.pending;
                          globalTabNotifier.value = 1; // Slide to Tasks Tab
                        },
                      ),
                      const SizedBox(width: 8),
                      _StatCard(
                        title: 'Overdue',
                        count: overdueCount,
                        onTap: () {
                          globalTaskFilterNotifier.value = TaskFilterCategory.overdue;
                          globalTabNotifier.value = 1; // Slide to Tasks Tab
                        },
                      ),
                      const SizedBox(width: 8),
                      _StatCard(
                        title: 'Done',
                        count: completedTasks.length,
                        onTap: () {
                          globalTaskFilterNotifier.value = TaskFilterCategory.completed;
                          globalTabNotifier.value = 1; // Slide to Tasks Tab
                        },
                      ),
                    ],
                  ),
                ),

                // 2. The New Analytics Charts!
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: DailyProgressRing(tasks: state.tasks),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: WeeklyBarChart(tasks: state.tasks),
                ),

                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Your Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),

                // 3. Task List
                if (state.tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No tasks yet. Tap + to add one!')),
                  )
                else ...[
                  // The Spread Operator (...) unpacks the tasks perfectly into the ListView
                  ...activeTasks.map((task) => _buildTaskRow(context, task)),

                  if (completedTasks.isNotEmpty)
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ExpansionTile(
                          key: const PageStorageKey('completed_tasks_dropdown'),
                          leading: const Icon(Icons.check_circle_outline, color: Colors.grey),
                          title: Text(
                            'Completed (${completedTasks.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16),
                          ),
                          children: completedTasks.map((task) => _buildTaskRow(context, task)).toList(),
                        ),
                      ),
                    ),
                ],
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100.0),
        child: FloatingActionButton(
          onPressed: () => TaskInputBottomSheet.show(context),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
          foregroundColor: Theme.of(context).colorScheme.surface,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTaskRow(BuildContext context, TaskEntity task) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade400,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Delete Task"),
              content: Text('Are you sure you want to delete "${task.title}"?'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        context.read<TaskBloc>().add(DeleteTaskEvent(task.id));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task deleted')));
      },
      child: TaskCard(
        task: task,
        onStatusChanged: (value) {
          TaskStatus newStatus;
          if (value == true) {
            newStatus = TaskStatus.completed;
          } else {
            final now = DateTime.now();
            bool isOverdue = false;
            if (task.endTime != null && task.endTime!.isBefore(now)) {
              isOverdue = true;
            } else if (task.endTime == null && task.deadline != null && task.deadline!.isBefore(now)) {
              isOverdue = true;
            }
            newStatus = isOverdue ? TaskStatus.overdue : TaskStatus.pending;
          }
          context.read<TaskBloc>().add(UpdateTaskEvent(task.copyWith(status: newStatus)));
        },
        onTap: () => TaskInputBottomSheet.show(context, existingTask: task),
      ),
    );
  }

  void _showNotificationCenter(BuildContext context, List<TaskEntity> activeTasks) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.purple),
                    SizedBox(width: 8),
                    Text('Upcoming Reminders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                if (activeTasks.isEmpty)
                  const Expanded(child: Center(child: Text('No active alarms set.', style: TextStyle(color: Colors.grey))))
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: activeTasks.length,
                      itemBuilder: (context, index) {
                        final task = activeTasks[index];
                        String alarmText = 'Alarm set';
                        if (task.startTime != null && task.reminderLeadMinutes != null) {
                          final ringTime = task.startTime!.subtract(Duration(minutes: task.reminderLeadMinutes!));
                          alarmText = 'Rings at ${DateFormat('MMM d, h:mm a').format(ringTime)}';
                        }
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(alarmText, style: const TextStyle(color: Colors.purple, fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            Navigator.pop(context);
                            TaskInputBottomSheet.show(context, existingTask: task);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onTap; // NEW: Receives the tap command

  const _StatCard({required this.title, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector( // NEW: Wraps the container to make it clickable
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: isDark ? null : Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}