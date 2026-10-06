import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../widgets/task_input_bottom_sheet.dart';
import '../../../../core/enums/task_status.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/entities/task_entity.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../widgets/task_card.dart';

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
    switch (_activeFilter) {
      case TaskFilterCategory.pending:
        return tasks.where((t) => t.status == TaskStatus.pending).toList();
      case TaskFilterCategory.completed:
        return tasks.where((t) => t.status == TaskStatus.completed).toList();
      case TaskFilterCategory.overdue:
      // FIXED: The database already marks them overdue, just filter by status!
        return tasks.where((t) => t.status == TaskStatus.overdue).toList();
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
                        // PRO UX: Only allow swiping right-to-left for deletion
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red.shade400,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                        ),
                        // PRO UX: Show a confirmation dialog before actually deleting
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
                          // This only runs if they clicked "Delete" in the dialog
                          context.read<TaskBloc>().add(DeleteTaskEvent(task.id));

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Task deleted')),
                          );
                        },
                        child: TaskCard(
                          task: task,
                          onStatusChanged: (value) {
                            TaskStatus newStatus;
                            if (value == true) {
                              newStatus = TaskStatus.completed;
                            } else {
                              // Smart check: If unchecked, evaluate if the time has already passed
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
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      // We wrap it in a Padding widget to lift it above the custom bottom nav bar
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100.0),
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
