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
        title: const Text('Solace Tasks'),
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
            if (state.tasks.isEmpty) {
              return const Center(child: Text('No tasks yet. Tap + to add one!'));
            }

            return ListView.builder(
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
                      color: task.status == TaskStatus.completed ? Colors.grey : null,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      context.read<TaskBloc>().add(DeleteTaskEvent(task.id));
                    },
                  ),
                );
              },
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