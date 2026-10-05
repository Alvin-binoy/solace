import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/enums/mood.dart';
import '../../domain/entities/journal_entry_entity.dart';
import '../bloc/journal_bloc.dart';
import '../bloc/journal_event.dart';
import '../widgets/mood_selector.dart';

class JournalEntryPage extends StatefulWidget {
  final JournalEntryEntity? existingEntry;

  const JournalEntryPage({super.key, this.existingEntry});

  @override
  State<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage> {
  late final TextEditingController _titleController;
  late final quill.QuillController _quillController;

  Mood? _selectedMood;
  List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingEntry?.title ?? '');
    _selectedMood = widget.existingEntry?.mood;
    _tags = List.from(widget.existingEntry?.tags ?? []);

    _initQuillController();
  }

  void _initQuillController() {
    if (widget.existingEntry != null && widget.existingEntry!.bodyJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(widget.existingEntry!.bodyJson);
        final document = quill.Document.fromJson(decoded);
        _quillController = quill.QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        _quillController = quill.QuillController.basic();
      }
    } else {
      _quillController = quill.QuillController.basic();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _saveEntry() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for your journal entry.')),
      );
      return;
    }

    final bodyJson = jsonEncode(_quillController.document.toDelta().toJson());
    final isEditing = widget.existingEntry != null;

    final entry = JournalEntryEntity(
      id: isEditing ? widget.existingEntry!.id : const Uuid().v4(),
      title: title,
      bodyJson: bodyJson,
      mood: _selectedMood,
      tags: _tags,
      createdAt: isEditing ? widget.existingEntry!.createdAt : DateTime.now(),
      updatedAt: isEditing ? DateTime.now() : null,
    );

    if (isEditing) {
      context.read<JournalBloc>().add(UpdateEntryEvent(entry));
    } else {
      context.read<JournalBloc>().add(AddEntryEvent(entry));
    }

    context.pop();
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
      setState(() {
        _tags.add(trimmed);
      });
    }
    _tagController.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.existingEntry == null ? 'New Entry' : 'Edit Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveEntry,
            tooltip: 'Save Entry',
          ),
        ],
      ),
      body: Column(
        children: [
          // FIXED: Updated syntax for flutter_quill v11+
          quill.QuillSimpleToolbar(
            controller: _quillController,
          ),
          Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'Title...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 16),

                  MoodSelector(
                    selectedMood: _selectedMood,
                    onMoodSelected: (mood) => setState(() => _selectedMood = mood),
                  ),
                  const SizedBox(height: 24),

                  // FIXED: Updated syntax for flutter_quill v11+
                  Container(
                    constraints: const BoxConstraints(minHeight: 200),
                    child: quill.QuillEditor.basic(
                      controller: _quillController,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Tags',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      // FIXED: Replaced .withOpacity to satisfy deprecation warnings
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._tags.map((tag) => Chip(
                        label: Text('#$tag'),
                        onDeleted: () => _removeTag(tag),
                        // FIXED: Replaced .withOpacity to satisfy deprecation warnings
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        deleteIconColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide.none,
                      )),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            hintText: '+ Add tag',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onSubmitted: _addTag,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}