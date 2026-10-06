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

  bool _showToolbar = true;

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
            icon: Icon(_showToolbar ? Icons.keyboard_arrow_up : Icons.text_format),
            tooltip: 'Toggle formatting toolbar',
            onPressed: () {
              setState(() {
                _showToolbar = !_showToolbar;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveEntry,
            tooltip: 'Save Entry',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              child: _showToolbar
                  ? Column(
                children: [
                  quill.QuillSimpleToolbar(
                    controller: _quillController,
                    config: const quill.QuillSimpleToolbarConfig(
                      multiRowsDisplay: false,
                    ),
                  ),
                  Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                ],
              )
                  : const SizedBox.shrink(),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // EDGE CASE FIXED: NestedScrollView allows the title to scroll away naturally
                    Expanded(
                      child: NestedScrollView(
                        headerSliverBuilder: (context, innerBoxIsScrolled) {
                          return [
                            SliverToBoxAdapter(
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
                                  const SizedBox(height: 8),
                                  MoodSelector(
                                    selectedMood: _selectedMood,
                                    onMoodSelected: (mood) => setState(() => _selectedMood = mood),
                                  ),
                                  const SizedBox(height: 16),
                                  Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ];
                        },
                        body: quill.QuillEditor.basic(
                          controller: _quillController,
                        ),
                      ),
                    ),

                    // Pinned Footer (Tags stay at the bottom, above the keyboard)
                    const SizedBox(height: 12),
                    Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ..._tags.map((tag) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(
                              label: Text('#$tag'),
                              onDeleted: () => _removeTag(tag),
                              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              deleteIconColor: Theme.of(context).colorScheme.primary,
                              side: BorderSide.none,
                            ),
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}