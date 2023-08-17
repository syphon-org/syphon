import 'package:drift/drift.dart';

///
///
///
/// Message Sessions Model (Table)
///
/// Meant to store all of crypto state in _cold storage_
///
class MessageSessions extends Table {
  TextColumn get id => text().unique()();

  TextColumn get roomId => text()();
  IntColumn get index => integer()();
  TextColumn get identityKey => text().nullable()(); // outbound keys have no identity
  TextColumn get session => text()();
  BoolColumn get inbound => boolean()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

///
/// Key Sessions Model (Table)
///
/// Meant to store all of crypto state in _cold storage_
///
class KeySessions extends Table {
  TextColumn get id => text().customConstraint('UNIQUE')();

  TextColumn get sessionId => text()();
  TextColumn get identityKey => text()();
  TextColumn get session => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
