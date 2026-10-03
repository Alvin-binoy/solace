import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
        title: const Text('My Dashboard'),
        automaticallyImplyLeading: false,
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

            // 1. Calculate our stats from the real-time tasks list
            final pending = state.tasks.where((t) => t.status == TaskStatus.pending).length;
            final completed = state.tasks.where((t) => t.status == TaskStatus.completed).length;
            final overdue = state.tasks.where((t) => t.status == TaskStatus.overdue).length;

            return Column(
              children: [
                // 2. The Summary Stats Row
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatCard(title: 'Pending', count: pending, color: Colors.orange),
                      _StatCard(title: 'Overdue', count: overdue, color: Colors.red),
                      _StatCard(title: 'Done', count: completed, color: Colors.green),
                    ],
                  ),
                ),
                const Divider(),

                // 3. The Task List (Now using TaskCard with Swipe-to-Delete)
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => TaskInputBottomSheet.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// A simple custom widget for the stat boxes
class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _StatCard({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }
}