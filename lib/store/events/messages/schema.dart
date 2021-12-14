import 'package:drift/drift.dart';
import 'package:syphon/storage/converters.dart';
import 'package:syphon/store/events/messages/model.dart';

///
/// Messages Model (Table)
///
/// Meant to store messages in _cold storage_
///
@UseRowClass(Message)
class Messages extends Table {
  // TextColumn get id => text().clientDefault(() => _uuid.v4())();

  // event base data
  TextColumn get id => text().customConstraint('UNIQUE')();
  TextColumn get roomId => text().nullable()(); // TODO: index on roomId
  TextColumn get userId => text().nullable()();
  TextColumn get type => text().nullable()();
  TextColumn get sender => text().nullable()();
  TextColumn get stateKey => text().nullable()();
  TextColumn get prevBatch => text().nullable()();
  TextColumn get batch => text().nullable()();

  // Message drafting
  BoolColumn get pending => boolean()();
  BoolColumn get syncing => boolean()();
  BoolColumn get failed => boolean()();

  // Message editing
  BoolColumn get edited => boolean()();
  BoolColumn get replacement => boolean()();

  // Message timestamps
  IntColumn get timestamp => integer()();
  IntColumn get received => integer()();

  // Message Only
  TextColumn get body => text().nullable()();
  TextColumn get msgtype => text().nullable()();
  TextColumn get format => text().nullable()();
  TextColumn get formattedBody => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get file => text().map(const MapToJsonConverter()).nullable()();

  // Encrypted Messages only
  TextColumn get typeDecrypted => text().nullable()(); // inner type of decrypted event
  TextColumn get ciphertext => text().nullable()();
  TextColumn get algorithm => text().nullable()();
  TextColumn get sessionId => text().nullable()();
  TextColumn get senderKey =>
      text().nullable()(); // Curve25519 device key which initiated the session
  TextColumn get deviceId => text().nullable()();
  TextColumn get relatedEventId => text().nullable()();

  TextColumn get editIds =>
      text().map(const ListToTextConverter()).withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

///
/// Decrypted Model (Table)
///
/// Meant to store messages in _cold storage_
///
/// TODO: implemented a quick AOT decryption will
/// prevent needing a cached table for this
///
@UseRowClass(Message)
class Decrypted extends Table {
  // TextColumn get id => text().clientDefault(() => _uuid.v4())();

  // event base data
  TextColumn get id => text().customConstraint('UNIQUE')();
  TextColumn get roomId => text().nullable()(); // TODO: index on roomId
  TextColumn get userId => text().nullable()();
  TextColumn get type => text().nullable()();
  TextColumn get sender => text().nullable()();
  TextColumn get stateKey => text().nullable()();
  TextColumn get prevBatch => text().nullable()();
  TextColumn get batch => text().nullable()();

  // Message drafting
  BoolColumn get pending => boolean()();
  BoolColumn get syncing => boolean()();
  BoolColumn get failed => boolean()();

  // Message editing
  BoolColumn get edited => boolean()();
  BoolColumn get replacement => boolean()();

  // Message timestamps
  IntColumn get timestamp => integer()();
  IntColumn get received => integer()();

  // Message Only
  TextColumn get body => text().nullable()();
  TextColumn get msgtype => text().nullable()();
  TextColumn get format => text().nullable()();
  TextColumn get formattedBody => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get file => text().map(const MapToJsonConverter()).nullable()();

  // Encrypted Messages only
  TextColumn get typeDecrypted => text().nullable()(); // inner type of decrypted event
  TextColumn get ciphertext => text().nullable()();
  TextColumn get algorithm => text().nullable()();
  TextColumn get sessionId => text().nullable()();
  TextColumn get senderKey =>
      text().nullable()(); // Curve25519 device key which initiated the session
  TextColumn get deviceId => text().nullable()();
  TextColumn get relatedEventId => text().nullable()();

  TextColumn get editIds =>
      text().map(const ListToTextConverter()).withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}
