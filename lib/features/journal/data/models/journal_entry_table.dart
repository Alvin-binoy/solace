import 'package:drift/drift.dart';
import '../../../../core/enums/mood.dart';

class JournalEntries extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 255)();

  // This will store the rich-text formatting (bold, italics) as a JSON string
  TextColumn get bodyJson => text()();

  TextColumn get mood => textEnum<Mood>().nullable()();
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // Stores a list of tags as a JSON array

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}