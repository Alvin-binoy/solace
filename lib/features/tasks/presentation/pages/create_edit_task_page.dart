import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

  bool _userOverridePriority = false;

  // NEW: Recurring Task State
  String? _recurrenceRule;

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

    _userOverridePriority = t?.userOverridePriority ?? false;

    // NEW: Load existing rule if editing
    _recurrenceRule = t?.recurrenceRule;

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

  void _showSmartMessage(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Hold on'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // NEW: The Recurrence Picker Dialog
  void _pickRecurrence() async {
    if (_scheduledDate == null) {
      _showSmartMessage('Please set a Schedule Date first.');
      return;
    }

    final Map<String?, String> options = {
      null: "Does not repeat",
      "FREQ=DAILY": "Daily",
      "FREQ=WEEKLY": "Weekly",
      "FREQ=MONTHLY": "Monthly"
    };

    await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Repeat Task'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        children: options.entries.map((entry) => SimpleDialogOption(
          onPressed: () {
            setState(() {
              _recurrenceRule = entry.key;
            });
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.value, style: const TextStyle(fontSize: 16)),
                if (_recurrenceRule == entry.key) const Icon(Icons.check, color: Colors.blueAccent),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  String _getRecurrenceText() {
    switch (_recurrenceRule) {
      case 'FREQ=DAILY': return 'Daily';
      case 'FREQ=WEEKLY': return 'Weekly';
      case 'FREQ=MONTHLY': return 'Monthly';
      default: return '';
    }
  }

  void _saveTask() {
    if (_titleController.text.trim().isEmpty) {
      _showSmartMessage('Title is required');
      return;
    }

    if (_scheduledDate == null) {
      _showSmartMessage('Please select a Schedule Date');
      return;
    }

    if ((_startTime != null && _endTime == null) || (_startTime == null && _endTime != null)) {
      _showSmartMessage('Please select both a Start and End time, or leave both empty');
      return;
    }

    if (_startTime != null && _endTime != null) {
      final startMinutes = (_startTime!.hour * 60) + _startTime!.minute;
      final endMinutes = (_endTime!.hour * 60) + _endTime!.minute;

      if (endMinutes <= startMinutes) {
        _showSmartMessage('End Time must be after the Start Time');
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
      userOverridePriority: _userOverridePriority,
      isRecurring: _recurrenceRule != null, // NEW: Saves recurring state
      recurrenceRule: _recurrenceRule,      // NEW: Saves the RRULE string
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
                        _userOverridePriority = true;
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
              if (picked != null) {
                setState(() => _scheduledDate = picked);
              }
            },
          ),

          // NEW: The Recurring Option in the main menu
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _recurrenceRule == null ? 'Repeat Task' : 'Repeats: ${_getRecurrenceText()}',
              style: TextStyle(
                color: _recurrenceRule == null ? Theme.of(context).colorScheme.onSurface : Colors.blueAccent,
                fontWeight: _recurrenceRule == null ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            trailing: Icon(
              _recurrenceRule == null ? Icons.repeat : Icons.repeat_on,
              color: _recurrenceRule == null ? Colors.grey : Colors.blueAccent,
            ),
            onTap: _pickRecurrence,
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
                      _showSmartMessage('Please select a Schedule Date first');
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
                      _showSmartMessage('Please select a Schedule Date first');
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