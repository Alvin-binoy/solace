import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../main.dart';
import '../widgets/task_input_bottom_sheet.dart';
import '../../../../core/enums/task_status.dart';
import '../../../../core/router/route_names.dart';
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

            final pending = state.tasks.where((t) => t.status == TaskStatus.pending).length;
            final completed = state.tasks.where((t) => t.status == TaskStatus.completed).length;
            final overdue = state.tasks.where((t) => t.status == TaskStatus.overdue).length;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      // Removed topLabel arguments
                      _StatCard(title: 'Pending', count: pending),
                      const SizedBox(width: 8),
                      _StatCard(title: 'Overdue', count: overdue),
                      const SizedBox(width: 8),
                      _StatCard(title: 'Done', count: completed),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: state.tasks.isEmpty
                      ? const Center(child: Text('No tasks yet. Tap + to add one!'))
                      : ListView.builder(
                    itemCount: state.tasks.length,
                    itemBuilder: (context, index) {
                      final task = state.tasks[index];

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
                            final newStatus = (value == true)
                                ? TaskStatus.completed
                                : TaskStatus.pending;
                            context
                                .read<TaskBloc>()
                                .add(UpdateTaskEvent(task.copyWith(status: newStatus)));
                          },
                          onTap: () => TaskInputBottomSheet.show(context, existingTask: task),
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
      // We wrap it in a Padding widget to lift it above the custom bottom nav bar
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          onPressed: () => TaskInputBottomSheet.show(context),
          backgroundColor: Theme.of(context).colorScheme.onSurface, // Invert colors for high contrast
          foregroundColor: Theme.of(context).colorScheme.surface,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

// Cleaned up _StatCard with topLabel removed entirely
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