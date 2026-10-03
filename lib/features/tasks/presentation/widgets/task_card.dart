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
  final scheduleText = _getScheduleText();

  final textColor = Theme.of(context).colorScheme.onSurface;
  final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

  return Card(
   child: InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Padding(
     // COMPACT: Reduced padding from 16 to 12
     padding: const EdgeInsets.all(12.0),
     child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         // COMPACT: Constraining the checkbox size so it doesn't add hidden padding
         SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
           value: isCompleted,
           onChanged: onStatusChanged,
           activeColor: textColor,
           checkColor: Theme.of(context).colorScheme.surface,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
           side: BorderSide(color: mutedTextColor, width: 1.5),
          ),
         ),
         const SizedBox(width: 10), // Tighter spacing

         // Task Title & Schedule
         Expanded(
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
            Text(
             task.title,
             style: TextStyle(
              fontSize: 16, // COMPACT: Reduced from 18
              fontWeight: FontWeight.w700,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? mutedTextColor : textColor,
              height: 1.2,
             ),
            ),
            if (task.description.isNotEmpty) ...[
             const SizedBox(height: 2), // Tighter spacing
             Text(
              task.description,
              style: TextStyle(fontSize: 13, color: mutedTextColor),
             ),
            ],
            if (scheduleText != null) ...[
             const SizedBox(height: 4), // Tighter spacing
             Row(
              children: [
               Icon(Icons.schedule, size: 12, color: mutedTextColor),
               const SizedBox(width: 4),
               Text(
                scheduleText,
                style: TextStyle(
                 fontSize: 11, // COMPACT: Reduced from 12
                 fontWeight: FontWeight.w600,
                 color: mutedTextColor,
                ),
               ),
              ],
             ),
            ],
           ],
          ),
         ),

         // Sleek Monochrome Priority Pill
         Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // Tighter padding
          decoration: BoxDecoration(
           color: Colors.transparent,
           borderRadius: BorderRadius.circular(10),
           border: Border.all(color: mutedTextColor.withOpacity(0.3)),
          ),
          child: Text(
           task.priority.name.toUpperCase(),
           style: TextStyle(
            fontSize: 9, // COMPACT: Reduced from 10
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isCompleted ? mutedTextColor : textColor,
           ),
          ),
         ),
        ],
       ),

       const SizedBox(height: 10), // Tighter spacing
       Divider(height: 1, color: mutedTextColor.withOpacity(0.2)),
       const SizedBox(height: 8), // Tighter spacing

       // Sleek Monochrome Category Label
       Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
         Icon(Icons.folder_outlined, size: 12, color: mutedTextColor),
         const SizedBox(width: 4),
         Text(
          task.category.name.toUpperCase(),
          style: TextStyle(
           fontSize: 10, // COMPACT: Reduced from 11
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