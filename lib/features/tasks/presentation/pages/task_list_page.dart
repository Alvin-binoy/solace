import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/task_status.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/entities/task_entity.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../widgets/task_card.dart';
import 'create_edit_task_page.dart';

enum TaskFilterCategory { all, pending, completed, overdue }

class TaskListPage extends StatelessWidget {
  const TaskListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<TaskBloc>()..add(WatchTasksEvent()),
      child: const _TaskListView(),
    );
  }
}

class _TaskListView extends StatefulWidget {
  const _TaskListView();

  @override
  State<_TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<_TaskListView> {
  TaskFilterCategory _activeFilter = TaskFilterCategory.all;

  List<TaskEntity> _filterTasks(List<TaskEntity> tasks) {
    final now = DateTime.now();
    switch (_activeFilter) {
      case TaskFilterCategory.pending:
        return tasks.where((t) => t.status == TaskStatus.pending).toList();
      case TaskFilterCategory.completed:
        return tasks.where((t) => t.status == TaskStatus.completed).toList();
      case TaskFilterCategory.overdue:
        return tasks.where((t) {
          return t.status == TaskStatus.pending &&
              t.deadline != null &&
              t.deadline!.isBefore(now);
        }).toList();
      case TaskFilterCategory.all:
        return tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: TaskFilterCategory.values.map((filter) {
                final isSelected = _activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      filter.name.toUpperCase(),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Theme.of(context).colorScheme.onPrimary : null,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    onSelected: (_) {
                      setState(() => _activeFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Task List
          Expanded(
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state is TaskLoading || state is TaskInitial) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is TaskError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (state is TaskLoaded) {
                  final filteredTasks = _filterTasks(state.tasks);

                  if (filteredTasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No ${_activeFilter.name} tasks found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];

                      return Dismissible(
                        key: Key(task.id),
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          if (direction == DismissDirection.startToEnd) {
                            // Toggle completion
                            final newStatus = task.status == TaskStatus.completed
                                ? TaskStatus.pending
                                : TaskStatus.completed;
                            context
                                .read<TaskBloc>()
                                .add(UpdateTaskEvent(task.copyWith(status: newStatus)));
                          } else {
                            // Delete
                            context.read<TaskBloc>().add(DeleteTaskEvent(task.id));
                          }
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: context.read<TaskBloc>(),
                                  child: CreateEditTaskPage(existingTask: task),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.taskCreate),
        child: const Icon(Icons.add),
      ),
    );
  }
}
