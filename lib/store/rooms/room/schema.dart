import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:syphon/storage/converters.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/rooms/room/model.dart';

class MessageToJsonConverter extends TypeConverter<Message?, String> {
  const MessageToJsonConverter();

  @override
  Message? mapToDart(String? fromDb) {
    return Message.fromJson(jsonDecode(fromDb ?? '{}') ?? {});
  }

  @override
  String? mapToSql(Message? value) {
    return json.encode(value);
  }
}

///
/// Messages Model (Table)
///
/// Meant to store messages in _cold storage_
///
@UseRowClass(Room)
class Rooms extends Table {
  // TextColumn get id => text().clientDefault(() => _uuid.v4())();

  TextColumn get id => text().customConstraint('UNIQUE')();
  TextColumn get name => text().nullable()();
  TextColumn get alias => text().nullable()();
  TextColumn get homeserver => text().nullable()();
  TextColumn get avatarUri => text().nullable()();
  TextColumn get topic => text().nullable()();
  TextColumn get joinRule => text().nullable()(); // "public", "knock", "invite", "private"

  BoolColumn get drafting => boolean()();
  BoolColumn get direct => boolean()();
  BoolColumn get sending => boolean()();
  BoolColumn get invite => boolean()();
  BoolColumn get guestEnabled => boolean()();
  BoolColumn get encryptionEnabled => boolean()();
  BoolColumn get worldReadable => boolean()();
  BoolColumn get hidden => boolean()();
  BoolColumn get archived => boolean()();

  TextColumn get lastBatch => text().nullable()(); // oldest hash in timeline
  TextColumn get prevBatch => text().nullable()(); // most recent prev_batch (not the lastBatch)
  TextColumn get nextBatch => text().nullable()(); // most recent next_batch

  IntColumn get lastRead => integer().withDefault(const Constant(0))();
  IntColumn get lastUpdate => integer().withDefault(const Constant(0))();
  IntColumn get totalJoinedUsers => integer().withDefault(const Constant(0))();
  IntColumn get namePriority => integer().withDefault(const Constant(4))();

  // Event lists and handlers
  TextColumn get draft => text().map(const MessageToJsonConverter()).nullable()();
  TextColumn get reply => text().map(const MessageToJsonConverter()).nullable()();

  // Associated user ids
  TextColumn get userIds =>
      text().map(const ListToTextConverter()).withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}
