import 'package:flutter/material.dart';
import '../../../../core/enums/task_category.dart';

class CategoryChip extends StatelessWidget {
  final TaskCategory category;

  const CategoryChip({super.key, required this.category});

  IconData _getIcon() {
    switch (category) {
      case TaskCategory.work:
        return Icons.work_outline;
      case TaskCategory.personal:
        return Icons.person_outline;
      case TaskCategory.health:
        return Icons.favorite_outline;
      case TaskCategory.study:
        return Icons.school_outlined;
      case TaskCategory.other:
        return Icons.label_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), size: 12),
          const SizedBox(width: 4),
          Text(
            category.name.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
