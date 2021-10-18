import 'dart:async';

import 'package:drift/drift.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/drift/database.dart';
import 'package:syphon/store/events/messages/model.dart';

///
/// Message Quesies - unencrypted (Cold Storage)
///
/// In storage, messages are indexed by eventId
/// In redux, they're indexed by RoomID and placed in a list
///
extension MessageQueries on StorageDatabase {
  Future<void> insertMessagesBatched(List<Message> messages) {
    return batch(
      (batch) => batch.insertAllOnConflictUpdate(
        this.messages,
        messages,
      ),
    );
  }

  Future<List<Message>> selectMessagesAll(List<String> ids) {
    return (select(messages)..where((tbl) => tbl.id.isIn(ids))).get();
  }

  Future<List<Message>> selectMessages(List<String> ids, {int offset = 0, int limit = 25}) {
    return (select(messages)
          ..where((tbl) => tbl.id.isIn(ids))
          ..limit(limit, offset: offset))
        .get();
  }

  Future<List<Message>> selectMessagesRoom(String roomId, {int offset = 0, int limit = 25}) {
    return (select(messages)
          ..where((tbl) => tbl.roomId.equals(roomId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.timestamp, mode: OrderingMode.desc)])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<List<Message>> searchMessageBodys(String text, {int offset = 0, int limit = 25}) {
    return (select(messages)
          ..where((tbl) => tbl.body.like('%$text%'))
          ..limit(limit, offset: offset))
        .get();
  }
}

Future<void> saveMessages(
  List<Message> messages, {
  required StorageDatabase storage,
}) async {
  await storage.insertMessagesBatched(messages);
}

Future<List<Message>> loadMessages(
  List<String> eventIds, {
  required StorageDatabase storage,
  int offset = 0,
  int limit = 25,
}) async {
  try {
    return storage.selectMessagesAll(eventIds); //  TODO: offset: offset, limit: limit);
  } catch (error) {
    printError(error.toString(), title: 'loadMessages');
    return [];
  }
}

Future<List<Message>> searchMessagesStored(
  String text, {
  required StorageDatabase storage,
}) {
  return storage.searchMessageBodys(text);
}

///
///  Decrypted Message Queries (Cold Storage)
///
/// In storage, messages are indexed by eventId
/// In redux, they're indexed by RoomID and placed in a list
///
/// TODO: implemented a quick AOT decryption will
/// prevent needing a cached table for this
//
extension DecryptedQueries on StorageDatabase {
  Future<void> insertDecryptedBatched(List<Message> decrypted) {
    return batch(
      (batch) => batch.insertAllOnConflictUpdate(
        this.decrypted,
        decrypted,
      ),
    );
  }

  Future<List<Message>> selectDecrypted(List<String> ids, {int offset = 0, int limit = 0}) {
    return (select(decrypted)
          ..where((tbl) => tbl.id.isIn(ids))
          ..limit(limit, offset: offset))
        .get();
  }

  Future<List<Message>> selectDecryptedRoom(String roomId, {int offset = 0, int limit = 25}) {
    return (select(decrypted)
          ..where((tbl) => tbl.roomId.equals(roomId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.timestamp, mode: OrderingMode.desc)])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<List<Message>> searchDecryptedBodys(String text, {int offset = 0, int limit = 25}) {
    return (select(decrypted)
          ..where((tbl) => tbl.body.like('%$text%'))
          ..limit(limit, offset: offset))
        .get();
  }
}

Future<void> saveDecrypted(
  List<Message> messages, {
  required StorageDatabase storage,
}) async {
  await storage.insertDecryptedBatched(messages);
}

Future<List<Message>> loadDecrypted(
  List<String> eventIds, {
  required StorageDatabase storage,
  int offset = 0,
  int limit = 25, // default amount loaded
}) async {
  try {
    return storage.selectDecrypted(eventIds); // TODO: // offset: offset, limit: limit);
  } catch (error) {
    printError(error.toString(), title: 'loadMessages');
    return [];
  }
}
