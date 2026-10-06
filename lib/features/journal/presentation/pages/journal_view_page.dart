import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/enums/mood.dart';
import '../bloc/journal_bloc.dart';
import '../bloc/journal_state.dart';

class JournalViewPage extends StatefulWidget {
  final String entryId;

  const JournalViewPage({super.key, required this.entryId});

  @override
  State<JournalViewPage> createState() => _JournalViewPageState();
}

class _JournalViewPageState extends State<JournalViewPage> {
  quill.QuillController? _quillController;
  String _lastBodyJson = '';

  // Parses the rich text JSON safely
  void _initOrUpdateController(String bodyJson) {
    if (bodyJson == _lastBodyJson && _quillController != null) return;

    try {
      final decoded = jsonDecode(bodyJson);
      final document = quill.Document.fromJson(decoded);
      _quillController = quill.QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
      _quillController = quill.QuillController.basic();
    }
    _lastBodyJson = bodyJson;
  }

  @override
  void dispose() {
    _quillController?.dispose();
    super.dispose();
  }

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

    return BlocBuilder<JournalBloc, JournalState>(
      builder: (context, state) {
        if (state is JournalLoaded) {
          // Find the latest version of this entry from the database
          final entryIndex = state.entries.indexWhere((e) => e.id == widget.entryId);

          // EDGE CASE: Safe fallback if entry is missing
          if (entryIndex == -1) {
            return Scaffold(
              appBar: AppBar(title: const Text('Entry Not Found')),
              body: const Center(child: Text('This entry no longer exists.')),
            );
          }

          final entry = state.entries[entryIndex];
          _initOrUpdateController(entry.bodyJson);

          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              backgroundColor: Colors.transparent, // Blends it into the background
              elevation: 0, // Removes the shadow
              scrolledUnderElevation: 0, // Prevents color tinting when scrolling
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Entry',
                  onPressed: () {
                    // Navigate to the editor and pass the full entity
                    context.push('/journal-entry', extra: entry);
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Date & Mood
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM d, yyyy • h:mm a').format(entry.createdAt),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      if (entry.mood != null)
                        Icon(
                          _getMoodIcon(entry.mood!),
                          color: _getMoodColor(entry.mood!, isDark),
                          size: 28,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    entry.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Rich Text Body (Read-Only)
                  IgnorePointer(
                    child: quill.QuillEditor.basic(
                      controller: _quillController!,
                    ),
                  ),

                  // Tags
                  if (entry.tags.isNotEmpty) ...[
                    const SizedBox(height: 40),
                    Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        // Loading fallback
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}