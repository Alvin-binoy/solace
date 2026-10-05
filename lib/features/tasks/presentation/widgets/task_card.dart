import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/enums/task_status.dart';
import '../../domain/entities/task_entity.dart';

class TaskCard extends StatelessWidget {
 final TaskEntity task;
 final ValueChanged<bool?> onStatusChanged;
 final VoidCallback onTap;

 const TaskCard({
  super.key,
  required this.task,
  required this.onStatusChanged,
  required this.onTap,
 });

 String? _getScheduleText() {
  if (task.scheduledAt == null) return null;
  String text = DateFormat('MMM d').format(task.scheduledAt!);
  if (task.startTime != null && task.endTime != null) {
   final start = DateFormat('h:mm a').format(task.startTime!);
   final end = DateFormat('h:mm a').format(task.endTime!);
   text += ' • $start - $end';
  } else if (task.startTime != null) {
   final start = DateFormat('h:mm a').format(task.startTime!);
   text += ' • $start';
  }
  return text;
 }

 @override
 Widget build(BuildContext context) {
  final isCompleted = task.status == TaskStatus.completed;
  final isOverdue = task.status == TaskStatus.overdue; // NEW: Check if overdue
  final scheduleText = _getScheduleText();

  final baseTextColor = Theme.of(context).colorScheme.onSurface;
  final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

  // NEW: Determine exact text color based on status
  final textColor = isCompleted
      ? mutedTextColor
      : isOverdue
      ? Colors.red.shade400
      : baseTextColor;

  return Card(
   child: InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Padding(
     padding: const EdgeInsets.all(12.0),
     child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
           value: isCompleted,
           onChanged: onStatusChanged,
           activeColor: baseTextColor,
           checkColor: Theme.of(context).colorScheme.surface,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
           side: BorderSide(
               color: isOverdue ? Colors.red.shade400 : mutedTextColor, // Red box if overdue
               width: 1.5
           ),
          ),
         ),
         const SizedBox(width: 10),

         // Task Title & Schedule
         Expanded(
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
            Text(
             task.title,
             style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: textColor, // Applies red if overdue
              height: 1.2,
             ),
            ),
            if (task.description.isNotEmpty) ...[
             const SizedBox(height: 2),
             Text(
              task.description,
              style: TextStyle(fontSize: 13, color: mutedTextColor),
             ),
            ],
            if (scheduleText != null) ...[
             const SizedBox(height: 4),
             Row(
              children: [
               Icon(
                   Icons.schedule,
                   size: 12,
                   color: isOverdue ? Colors.red.shade400 : mutedTextColor // Red clock if overdue
               ),
               const SizedBox(width: 4),
               Text(
                scheduleText,
                style: TextStyle(
                 fontSize: 11,
                 fontWeight: FontWeight.w600,
                 color: isOverdue ? Colors.red.shade400 : mutedTextColor, // Red time if overdue
                ),
               ),
               if (task.reminderLeadMinutes != null && !isCompleted) ...[
                const SizedBox(width: 6),
                const Icon(Icons.notifications_active, size: 12, color: Colors.purple),
               ],
              ],
             ),
            ],
           ],
          ),
         ),

         // Priority Pill
         Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
           color: Colors.transparent,
           borderRadius: BorderRadius.circular(10),
           border: Border.all(
               color: isOverdue
                   ? Colors.red.shade400
                   : mutedTextColor.withOpacity(0.3)
           ), // Red border if overdue
          ),
          child: Text(
           task.priority.name.toUpperCase(),
           style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isCompleted ? mutedTextColor : baseTextColor,
           ),
          ),
         ),
        ],
       ),

       const SizedBox(height: 10),
       Divider(height: 1, color: mutedTextColor.withOpacity(0.2)),
       const SizedBox(height: 8),

       // Category Label
       Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
         Icon(Icons.folder_outlined, size: 12, color: mutedTextColor),
         const SizedBox(width: 4),
         Text(
          task.category.name.toUpperCase(),
          style: TextStyle(
           fontSize: 10,
           fontWeight: FontWeight.w700,
           letterSpacing: 0.5,
           color: mutedTextColor,
          ),
         ),
        ],
       ),
      ],
     ),
    ),
   ),
  );
 }
}