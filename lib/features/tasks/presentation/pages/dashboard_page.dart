import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/task_status.dart';
import '../../../../core/router/route_names.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';

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

                // 3. The Task List
                Expanded(
                  child: state.tasks.isEmpty
                      ? const Center(child: Text('No tasks yet. Tap + to add one!'))
                      : ListView.builder(
                    itemCount: state.tasks.length,
                    itemBuilder: (context, index) {
                      final task = state.tasks[index];
                      return ListTile(
                        leading: Checkbox(
                          value: task.status == TaskStatus.completed,
                          onChanged: (value) {
                            final newStatus = (value == true)
                                ? TaskStatus.completed
                                : TaskStatus.pending;
                            final updatedTask = task.copyWith(status: newStatus);
                            context.read<TaskBloc>().add(UpdateTaskEvent(updatedTask));
                          },
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.status == TaskStatus.completed
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.status == TaskStatus.completed
                                ? Colors.grey
                                : (task.status == TaskStatus.overdue ? Colors.red : null),
                          ),
                        ),
                        // Show an overdue label if needed
                        subtitle: task.status == TaskStatus.overdue
                            ? const Text('OVERDUE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () {
                            context.read<TaskBloc>().add(DeleteTaskEvent(task.id));
                          },
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
        onPressed: () => context.push(RouteNames.taskCreate),
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