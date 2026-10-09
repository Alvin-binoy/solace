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

  DateTime? _scheduledDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime? _deadline;

  bool _userOverridePriority = false; // NEW FLAG

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _priority = t?.priority ?? TaskPriority.medium;
    _category = t?.category ?? TaskCategory.personal;

    _scheduledDate = t?.scheduledAt;
    _deadline = t?.deadline;

    _userOverridePriority = t?.userOverridePriority ?? false; // LOAD FLAG

    if (t?.startTime != null) {
      _startTime = TimeOfDay(hour: t!.startTime!.hour, minute: t.startTime!.minute);
    }
    if (t?.endTime != null) {
      _endTime = TimeOfDay(hour: t!.endTime!.hour, minute: t.endTime!.minute);
    }
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

    if (_scheduledDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Schedule Date')),
      );
      return;
    }

    if ((_startTime != null && _endTime == null) || (_startTime == null && _endTime != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both a Start and End time, or leave both empty')),
      );
      return;
    }

    if (_startTime != null && _endTime != null) {
      final startMinutes = (_startTime!.hour * 60) + _startTime!.minute;
      final endMinutes = (_endTime!.hour * 60) + _endTime!.minute;

      if (endMinutes <= startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End Time must be after the Start Time')),
        );
        return;
      }
    }

    DateTime? finalStartTime;
    DateTime? finalEndTime;
    final baseDate = _scheduledDate!;

    if (_startTime != null) {
      finalStartTime = DateTime(
          baseDate.year, baseDate.month, baseDate.day, _startTime!.hour, _startTime!.minute);
    }
    if (_endTime != null) {
      finalEndTime = DateTime(
          baseDate.year, baseDate.month, baseDate.day, _endTime!.hour, _endTime!.minute);
    }

    final isEditing = widget.existingTask != null;
    final task = TaskEntity(
      id: isEditing ? widget.existingTask!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      priority: _priority,
      category: _category,
      status: isEditing ? widget.existingTask!.status : TaskStatus.pending,
      scheduledAt: _scheduledDate,
      startTime: finalStartTime,
      endTime: finalEndTime,
      deadline: _deadline,
      userOverridePriority: _userOverridePriority, // SAVE FLAG
      createdAt: isEditing ? widget.existingTask!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (isEditing) {
      context.read<TaskBloc>().add(UpdateTaskEvent(task));
    } else {
      context.read<TaskBloc>().add(AddTaskEvent(task));
    }

    context.pop();
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
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<TaskPriority>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: TaskPriority.values
                      .map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase())))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _priority = val;
                        _userOverridePriority = true; // TRIGGER OVERRIDE FLAG
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<TaskCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: TaskCategory.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.name.toUpperCase())))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text('Scheduling', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_scheduledDate == null
                ? 'Schedule Date'
                : 'Date: ${_scheduledDate.toString().split(' ')[0]}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _scheduledDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _scheduledDate = picked);
            },
          ),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                      _startTime == null ? 'Start Time (Optional)' : _startTime!.format(context),
                      style: const TextStyle(fontSize: 14)
                  ),
                  trailing: _startTime == null
                      ? const Icon(Icons.access_time, size: 20)
                      : IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() => _startTime = null),
                  ),
                  onTap: () async {
                    if (_scheduledDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a Schedule Date first')),
                      );
                      return;
                    }
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _startTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) setState(() => _startTime = picked);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                      _endTime == null ? 'End Time (Optional)' : _endTime!.format(context),
                      style: const TextStyle(fontSize: 14)
                  ),
                  trailing: _endTime == null
                      ? const Icon(Icons.access_time, size: 20)
                      : IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() => _endTime = null),
                  ),
                  onTap: () async {
                    if (_scheduledDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a Schedule Date first')),
                      );
                      return;
                    }
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _endTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) setState(() => _endTime = picked);
                  },
                ),
              ),
            ],
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