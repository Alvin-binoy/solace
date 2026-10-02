import 'package:equatable/equatable.dart';
import '../../../../core/enums/task_category.dart';
import '../../../../core/enums/task_priority.dart';
import '../../../../core/enums/task_status.dart';

class TaskEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskCategory category;
  final TaskStatus status;
  final DateTime? deadline;
  final DateTime? scheduledAt;
  final bool isRecurring;
  final String? recurrenceRule;
  final String? parentTaskId;
  final int? reminderLeadMinutes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TaskEntity({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.personal,
    this.status = TaskStatus.pending,
    this.deadline,
    this.scheduledAt,
    this.isRecurring = false,
    this.recurrenceRule,
    this.parentTaskId,
    this.reminderLeadMinutes,
    required this.createdAt,
    this.updatedAt,
  });

  TaskEntity copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskCategory? category,
    TaskStatus? status,
    DateTime? deadline,
    DateTime? scheduledAt,
    bool? isRecurring,
    String? recurrenceRule,
    String? parentTaskId,
    int? reminderLeadMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      reminderLeadMinutes: reminderLeadMinutes ?? this.reminderLeadMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    priority,
    category,
    status,
    deadline,
    scheduledAt,
    isRecurring,
    recurrenceRule,
    parentTaskId,
    reminderLeadMinutes,
    createdAt,
    updatedAt,
  ];
}
