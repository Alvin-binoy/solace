import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/task_category.dart';
import '../../../../core/enums/task_priority.dart';
import '../../../../core/enums/task_status.dart';
import '../../domain/entities/task_entity.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';

class CreateEditTaskPage extends StatefulWidget {
  final TaskEntity? existingTask;

  const CreateEditTaskPage({super.key, this.existingTask});

  @override
  State<CreateEditTaskPage> createState() => _CreateEditTaskPageState();
}

class _CreateEditTaskPageState extends State<CreateEditTaskPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TaskPriority _priority;
  late TaskCategory _category;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _priority = t?.priority ?? TaskPriority.medium;
    _category = t?.category ?? TaskCategory.personal;
    _deadline = t?.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveTask() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    final isEditing = widget.existingTask != null;
    final task = TaskEntity(
      id: isEditing ? widget.existingTask!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      priority: _priority,
      category: _category,
      status: isEditing ? widget.existingTask!.status : TaskStatus.pending,
      deadline: _deadline,
      createdAt: isEditing ? widget.existingTask!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (isEditing) {
      context.read<TaskBloc>().add(UpdateTaskEvent(task));
    } else {
      context.read<TaskBloc>().add(AddTaskEvent(task));
    }

    context.pop(); // Return to previous screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTask == null ? 'New Task' : 'Edit Task'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Task Title'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Description (optional)'),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TaskPriority>(
            initialValue: _priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: TaskPriority.values
                .map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase())))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _priority = val);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TaskCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: TaskCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.name.toUpperCase())))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _category = val);
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_deadline == null
                ? 'No deadline set'
                : 'Deadline: ${_deadline.toString().split(' ')[0]}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _deadline ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _deadline = picked);
              }
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saveTask,
            child: const Text('Save Task'),
          )
        ],
      ),
    );
  }
}
