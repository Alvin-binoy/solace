import 'package:flutter/material.dart';
import '../../../../core/enums/mood.dart';

class MoodSelector extends StatelessWidget {
  final Mood? selectedMood;
  final ValueChanged<Mood> onMoodSelected;

  const MoodSelector({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  IconData _getMoodIcon(Mood mood) {
    switch (mood) {
      case Mood.awful: return Icons.sentiment_very_dissatisfied;
      case Mood.bad: return Icons.sentiment_dissatisfied;
      case Mood.neutral: return Icons.sentiment_neutral;
      case Mood.good: return Icons.sentiment_satisfied;
      case Mood.great: return Icons.sentiment_very_satisfied;
    }
  }

  Color _getMoodColor(Mood mood, bool isDark) {
    switch (mood) {
      case Mood.awful: return Colors.red.shade400;
      case Mood.bad: return Colors.orange.shade400;
      case Mood.neutral: return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
      case Mood.good: return Colors.lightGreen.shade400;
      case Mood.great: return Colors.green.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: Mood.values.map((mood) {
              final isSelected = selectedMood == mood;
              final activeColor = _getMoodColor(mood, isDark);

              return GestureDetector(
                onTap: () => onMoodSelected(mood),
                behavior: HitTestBehavior.opaque,
                child: AnimatedScale(
                  scale: isSelected ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor.withOpacity(0.2) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getMoodIcon(mood),
                      size: 32,
                      color: isSelected ? activeColor : Colors.grey.withOpacity(0.5),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}