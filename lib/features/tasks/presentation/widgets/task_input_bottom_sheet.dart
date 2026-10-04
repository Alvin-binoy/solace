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

  // NEW: Track if the user has explicitly interacted with these
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Start and End time must be set together. Time cleared.')),
          );
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
                // NEW: Show a checkmark for the currently selected item
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
        _hasModifiedPriority = true; // Show the chip!
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
                // NEW: Show a checkmark for the currently selected item
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
        _hasModifiedCategory = true; // Show the chip!
      });
    }
  }

  void _saveTask() {
    if (_titleController.text.trim().isEmpty) return;

    if (_startTime != null && _endTime != null) {
      final startMins = (_startTime!.hour * 60) + _startTime!.minute;
      final endMins = (_endTime!.hour * 60) + _endTime!.minute;
      if (endMins <= startMins) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End Time must be after Start Time')),
        );
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

          // Chips Row
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
                  }),
                ),
              if (_startTime != null && _endTime != null)
                InputChip(
                  label: Text('${_startTime!.format(context)} - ${_endTime!.format(context)}'),
                  onDeleted: () => setState(() {
                    _startTime = null;
                    _endTime = null;
                  }),
                ),
              // Show Priority if it's explicitly modified OR not the default
              if (_hasModifiedPriority || _priority != TaskPriority.medium)
                InputChip(
                  avatar: const Icon(Icons.flag, size: 16, color: Colors.deepOrange),
                  label: Text(_priority.name.toUpperCase()),
                  onPressed: _pickPriority,
                  onDeleted: () => setState(() {
                    _priority = TaskPriority.medium;
                    _hasModifiedPriority = false; // Hide it again on delete
                  }),
                ),
              // Show Category if it's explicitly modified OR not the default
              if (_hasModifiedCategory || _category != TaskCategory.personal)
                InputChip(
                  avatar: const Icon(Icons.folder_outlined, size: 16, color: Colors.blue),
                  label: Text(_category.name.toUpperCase()),
                  onPressed: _pickCategory,
                  onDeleted: () => setState(() {
                    _category = TaskCategory.personal;
                    _hasModifiedCategory = false; // Hide it again on delete
                  }),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Bottom Action Bar
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