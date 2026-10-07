import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/enums/task_category.dart';
import '../../../../core/enums/task_priority.dart';
import '../../../../core/enums/task_status.dart';
import '../../domain/entities/task_entity.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';

class TaskInputBottomSheet extends StatefulWidget {
  final TaskEntity? existingTask;

  const TaskInputBottomSheet({super.key, this.existingTask});

  static void show(BuildContext context, {TaskEntity? existingTask}) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<TaskBloc>(),
        child: TaskInputBottomSheet(existingTask: existingTask),
      ),
    );
  }

  @override
  State<TaskInputBottomSheet> createState() => _TaskInputBottomSheetState();
}

class _TaskInputBottomSheetState extends State<TaskInputBottomSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descController;

  bool _showDescription = false;
  DateTime? _scheduledDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  late TaskPriority _priority;
  late TaskCategory _category;

  int? _reminderLeadMinutes;

  bool _hasModifiedPriority = false;
  bool _hasModifiedCategory = false;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _showDescription = _descController.text.isNotEmpty;
    _scheduledDate = t?.scheduledAt;

    _priority = t?.priority ?? TaskPriority.medium;
    _category = t?.category ?? TaskCategory.personal;

    _reminderLeadMinutes = t?.reminderLeadMinutes;

    if (t != null) {
      _hasModifiedPriority = true;
      _hasModifiedCategory = true;
    }

    if (t?.startTime != null) {
      _startTime = TimeOfDay.fromDateTime(t!.startTime!);
    }
    if (t?.endTime != null) {
      _endTime = TimeOfDay.fromDateTime(t!.endTime!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // NEW: Smart message helper that floats above the keyboard!
  void _showSmartMessage(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          // Dynamically pushes the snackbar above the keyboard height!
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  void _pickTime() async {
    if (_scheduledDate == null) {
      setState(() => _scheduledDate = DateTime.now());
    }

    final pickedStart = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      helpText: 'Select Start Time',
    );

    if (pickedStart != null) {
      if (mounted) {
        final pickedEnd = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: (pickedStart.hour + 1) % 24, minute: pickedStart.minute),
          helpText: 'Select End Time',
        );

        if (pickedEnd != null) {
          setState(() {
            _startTime = pickedStart;
            _endTime = pickedEnd;
          });
        } else {
          _showSmartMessage('Start and End time must be set together. Time cleared.');
          setState(() {
            _startTime = null;
            _endTime = null;
          });
        }
      }
    }
  }

  void _pickPriority() async {
    final picked = await showDialog<TaskPriority>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Priority'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        children: TaskPriority.values.map((p) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, p),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(p.name.toUpperCase(), style: const TextStyle(fontSize: 16)),
                if (_priority == p) const Icon(Icons.check, color: Colors.deepOrange),
              ],
            ),
          ),
        )).toList(),
      ),
    );
    if (picked != null) {
      setState(() {
        _priority = picked;
        _hasModifiedPriority = true;
      });
    }
  }

  void _pickCategory() async {
    final picked = await showDialog<TaskCategory>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Category'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        children: TaskCategory.values.map((c) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, c),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(c.name.toUpperCase(), style: const TextStyle(fontSize: 16)),
                if (_category == c) const Icon(Icons.check, color: Colors.blue),
              ],
            ),
          ),
        )).toList(),
      ),
    );
    if (picked != null) {
      setState(() {
        _category = picked;
        _hasModifiedCategory = true;
      });
    }
  }

  void _pickReminderSafe() async {
    if (_scheduledDate == null || _startTime == null) {
      _showSmartMessage('Please set a Date and Start Time before setting an alarm.');
      return;
    }

    final Map<int?, String> options = {
      null: "No alarm",
      0: "At time of task",
      5: "5 minutes before",
      15: "15 minutes before",
      30: "30 minutes before",
      60: "1 hour before"
    };

    await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Set Reminder'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        children: options.entries.map((entry) => SimpleDialogOption(
          onPressed: () {
            setState(() {
              _reminderLeadMinutes = entry.key;
            });
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.value, style: const TextStyle(fontSize: 16)),
                if (_reminderLeadMinutes == entry.key) const Icon(Icons.check, color: Colors.purple),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  String _getReminderText() {
    switch (_reminderLeadMinutes) {
      case 0: return 'At time of task';
      case 5: return '5 min before';
      case 15: return '15 min before';
      case 30: return '30 min before';
      case 60: return '1 hour before';
      default: return '';
    }
  }

  void _saveTask() {
    if (_titleController.text.trim().isEmpty) return;

    if (_startTime != null && _endTime != null) {
      final startMins = (_startTime!.hour * 60) + _startTime!.minute;
      final endMins = (_endTime!.hour * 60) + _endTime!.minute;
      if (endMins <= startMins) {
        _showSmartMessage('End Time must be after Start Time');
        return;
      }
    }

    DateTime? finalStartTime;
    DateTime? finalEndTime;

    if (_scheduledDate != null) {
      if (_startTime != null) {
        finalStartTime = DateTime(_scheduledDate!.year, _scheduledDate!.month,
            _scheduledDate!.day, _startTime!.hour, _startTime!.minute);
      }
      if (_endTime != null) {
        finalEndTime = DateTime(_scheduledDate!.year, _scheduledDate!.month,
            _scheduledDate!.day, _endTime!.hour, _endTime!.minute);
      }
    }

    if (_reminderLeadMinutes != null && finalStartTime == null && _scheduledDate == null) {
      _showSmartMessage('Please set a date or time for the alarm to trigger.');
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
      scheduledAt: _scheduledDate,
      deadline: _scheduledDate,
      startTime: finalStartTime,
      endTime: finalEndTime,
      reminderLeadMinutes: _reminderLeadMinutes,
      createdAt: isEditing ? widget.existingTask!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (isEditing) {
      context.read<TaskBloc>().add(UpdateTaskEvent(task));
    } else {
      context.read<TaskBloc>().add(AddTaskEvent(task));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              hintText: 'New task',
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _saveTask(),
          ),

          if (_showDescription)
            TextField(
              controller: _descController,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Add details',
                border: InputBorder.none,
              ),
              maxLines: null,
            ),

          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (_scheduledDate != null)
                InputChip(
                  label: Text(DateFormat('MMM d').format(_scheduledDate!)),
                  onDeleted: () => setState(() {
                    _scheduledDate = null;
                    _startTime = null;
                    _endTime = null;
                    _reminderLeadMinutes = null;
                  }),
                ),
              if (_startTime != null && _endTime != null)
                InputChip(
                  label: Text('${_startTime!.format(context)} - ${_endTime!.format(context)}'),
                  onDeleted: () => setState(() {
                    _startTime = null;
                    _endTime = null;
                    _reminderLeadMinutes = null;
                  }),
                ),
              if (_hasModifiedPriority || _priority != TaskPriority.medium)
                InputChip(
                  avatar: const Icon(Icons.flag, size: 16, color: Colors.deepOrange),
                  label: Text(_priority.name.toUpperCase()),
                  onPressed: _pickPriority,
                  onDeleted: () => setState(() {
                    _priority = TaskPriority.medium;
                    _hasModifiedPriority = false;
                  }),
                ),
              if (_hasModifiedCategory || _category != TaskCategory.personal)
                InputChip(
                  avatar: const Icon(Icons.folder_outlined, size: 16, color: Colors.blue),
                  label: Text(_category.name.toUpperCase()),
                  onPressed: _pickCategory,
                  onDeleted: () => setState(() {
                    _category = TaskCategory.personal;
                    _hasModifiedCategory = false;
                  }),
                ),
              if (_reminderLeadMinutes != null)
                InputChip(
                  avatar: const Icon(Icons.notifications_active, size: 16, color: Colors.purple),
                  label: Text(_getReminderText()),
                  onPressed: _pickReminderSafe,
                  onDeleted: () => setState(() {
                    _reminderLeadMinutes = null;
                  }),
                ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notes),
                tooltip: 'Add details',
                onPressed: () => setState(() => _showDescription = !_showDescription),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month),
                tooltip: 'Set date',
                onPressed: _pickDate,
              ),
              IconButton(
                icon: const Icon(Icons.access_time),
                tooltip: 'Set time block',
                onPressed: _pickTime,
              ),
              IconButton(
                icon: Icon(Icons.flag_outlined, color: _priority != TaskPriority.medium ? Colors.deepOrange : null),
                tooltip: 'Set Priority',
                onPressed: _pickPriority,
              ),
              IconButton(
                icon: Icon(Icons.folder_outlined, color: _category != TaskCategory.personal ? Colors.blue : null),
                tooltip: 'Set Category',
                onPressed: _pickCategory,
              ),
              IconButton(
                icon: Icon(
                    _reminderLeadMinutes != null ? Icons.notifications_active : Icons.notifications_none,
                    color: _reminderLeadMinutes != null ? Colors.purple : null
                ),
                tooltip: 'Set Reminder',
                onPressed: _pickReminderSafe,
              ),
              const Spacer(),
              TextButton(
                onPressed: _saveTask,
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}