import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../main.dart';
import '../widgets/task_input_bottom_sheet.dart';
import '../../../../core/enums/task_status.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/entities/task_entity.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../widgets/task_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DASHBOARD'),
        automaticallyImplyLeading: false,
        actions: [
          // NEW: StreamBuilder acts as a real-time clock, forcing the bell to refresh every 30 seconds
          StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 30)),
              builder: (context, _) {
                return BlocBuilder<TaskBloc, TaskState>(
                  builder: (context, state) {
                    int activeAlarmsCount = 0;
                    List<TaskEntity> activeAlarmTasks = [];

                    if (state is TaskLoaded) {
                      final now = DateTime.now();

                      // Filter only pending tasks with a future reminder
                      activeAlarmTasks = state.tasks.where((t) {
                        if (t.status == TaskStatus.completed || t.reminderLeadMinutes == null || t.startTime == null) {
                          return false;
                        }
                        // Calculate exact ring time
                        final ringTime = t.startTime!.subtract(Duration(minutes: t.reminderLeadMinutes!));

                        // ONLY keep it if the ring time hasn't passed yet
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
                      onPressed: () {
                        _showNotificationCenter(context, activeAlarmTasks);
                      },
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
            return Center(
              child: Text(state.message, style: const TextStyle(color: Colors.red)),
            );
          } else if (state is TaskLoaded) {

            // 1. Split data into active and completed
            final activeTasks = state.tasks.where((t) => t.status != TaskStatus.completed).toList();
            final completedTasks = state.tasks.where((t) => t.status == TaskStatus.completed).toList();

            final pendingCount = state.tasks.where((t) => t.status == TaskStatus.pending).length;
            final overdueCount = state.tasks.where((t) => t.status == TaskStatus.overdue).length;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      _StatCard(title: 'Pending', count: pendingCount),
                      const SizedBox(width: 8),
                      _StatCard(title: 'Overdue', count: overdueCount),
                      const SizedBox(width: 8),
                      _StatCard(title: 'Done', count: completedTasks.length),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: state.tasks.isEmpty
                      ? const Center(child: Text('No tasks yet. Tap + to add one!'))
                      : ListView.builder(
                    // Total item count is active tasks + 1 (the completed dropdown tile if it has items)
                    itemCount: activeTasks.length + (completedTasks.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {

                      // Build Active Tasks
                      if (index < activeTasks.length) {
                        return _buildTaskRow(context, activeTasks[index]);
                      }

                      // Build the Completed Dropdown at the very bottom
                      return Theme(
                        // Removes the ugly default borders around ExpansionTile
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ExpansionTile(
                            key: const PageStorageKey('completed_tasks_dropdown'),
                            leading: const Icon(Icons.check_circle_outline, color: Colors.grey),
                            title: Text(
                              'Completed (${completedTasks.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            children: completedTasks.map((task) => _buildTaskRow(context, task)).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
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

  // NEW: Helper method to build a task row so we don't duplicate the Dismissible code
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
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        context.read<TaskBloc>().add(DeleteTaskEvent(task.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted')),
        );
      },
      child: TaskCard(
        task: task,
        onStatusChanged: (value) {
          final newStatus = (value == true) ? TaskStatus.completed : TaskStatus.pending;
          context.read<TaskBloc>().add(UpdateTaskEvent(task.copyWith(status: newStatus)));
        },
        onTap: () => TaskInputBottomSheet.show(context, existingTask: task),
      ),
    );
  }

  // Bottom Sheet for the Notification Center
  void _showNotificationCenter(BuildContext context, List<TaskEntity> activeTasks) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
                    Text(
                      'Upcoming Reminders',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (activeTasks.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No active alarms set.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: activeTasks.length,
                      itemBuilder: (context, index) {
                        final task = activeTasks[index];

                        // Calculate exact time the alarm rings
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
                            Navigator.pop(context); // Close sheet
                            // Open task for editing
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

  const _StatCard({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: isDark ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count.toString(),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}