import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:intl/intl.dart';

import '../../../../core/enums/mood.dart';
import '../../domain/entities/journal_entry_entity.dart';

class JournalCard extends StatelessWidget {
  final JournalEntryEntity entry;
  final VoidCallback onTap;

  const JournalCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  // EDGE CASE: Safely extract plain text from the Quill Delta JSON.
  String _getPreviewText() {
    try {
      if (entry.bodyJson.isEmpty) return '';
      final decoded = jsonDecode(entry.bodyJson);
      final document = quill.Document.fromJson(decoded);
      final plainText = document.toPlainText();
      return plainText.trim();
    } catch (e) {
      return 'Tap to view entry...';
    }
  }

  IconData? _getMoodIcon(Mood mood) {
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
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    final previewText = _getPreviewText();

    return Card(
      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Date and Mood
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM d, yyyy • h:mm a').format(entry.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: mutedTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (entry.mood != null)
                    Icon(
                      _getMoodIcon(entry.mood!),
                      size: 20,
                      color: _getMoodColor(entry.mood!, isDark),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                entry.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Preview Text
              if (previewText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  previewText,
                  style: TextStyle(
                    fontSize: 14,
                    color: mutedTextColor,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Tags Row
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}