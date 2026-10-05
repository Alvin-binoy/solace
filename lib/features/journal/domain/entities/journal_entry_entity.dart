import 'package:equatable/equatable.dart';
import '../../../../core/enums/mood.dart';

class JournalEntryEntity extends Equatable {
  final String id;
  final String title;
  final String bodyJson; // This holds the rich-text formatting
  final Mood? mood;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const JournalEntryEntity({
    required this.id,
    required this.title,
    required this.bodyJson,
    this.mood,
    this.tags = const [], // EDGE CASE: Prevents null errors if no tags are added
    required this.createdAt,
    this.updatedAt,
  });

  JournalEntryEntity copyWith({
    String? id,
    String? title,
    String? bodyJson,
    Mood? mood,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntryEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      bodyJson: bodyJson ?? this.bodyJson,
      // If we specifically want to clear the mood, we would need a more complex copyWith,
      // but for this app, replacing it with the existing mood if null is safe.
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    bodyJson,
    mood,
    tags,
    createdAt,
    updatedAt,
  ];
}