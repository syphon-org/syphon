import 'package:drift/drift.dart';
import 'package:syphon/store/events/reactions/model.dart';

///
/// Reactions Model (Table)
///
/// Meant to store reactions in _cold storage_
///
@UseRowClass(Reaction)
class Reactions extends Table {
  // Event Base Date
  TextColumn get id => text().customConstraint('UNIQUE')();
  TextColumn get roomId => text().nullable()();
  TextColumn get userId => text().nullable()();
  TextColumn get type => text().nullable()();
  TextColumn get sender => text().nullable()();
  TextColumn get stateKey => text().nullable()();
  TextColumn get batch => text().nullable()();
  TextColumn get prevBatch => text().nullable()();

  // Event Timestamps
  IntColumn get timestamp => integer()();

  // Message Only
  TextColumn get body => text().nullable()();
  TextColumn get relType => text().nullable()();
  TextColumn get relEventId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
