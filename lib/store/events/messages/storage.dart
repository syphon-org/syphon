import 'dart:async';
import 'dart:convert';

import 'package:moor/moor.dart';
import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/storage/moor/database.dart';
import 'package:syphon/store/events/messages/model.dart';

// example of loading queries separate from the database object
extension MessageQueries on StorageDatabase {
  Future<void> insertMessagesBatched(List<Message> messages) {
    return batch(
      (batch) => batch.insertAllOnConflictUpdate(
        this.messages,
        messages,
      ),
    );
  }

  Future<List<Message>> selectMessages(List<String> ids, {int offset = 0, int limit = 25}) {
    return (select(messages)
          ..where((tbl) => tbl.id.isIn(ids))
          ..limit(25, offset: offset))
        .get();
  }

  Future<List<Message>> selectMessagesRoom(String roomId, {int offset = 0, int limit = 25}) {
    return (select(messages)
          ..where((tbl) => tbl.roomId.equals(roomId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.timestamp, mode: OrderingMode.desc)])
          ..limit(25, offset: offset))
        .get();
  }

  Future<List<Message>> searchMessageBodys(String text, {int offset = 0, int limit = 25}) {
    return (select(messages)
          ..where((tbl) => tbl.body.like('%$text%'))
          ..limit(25, offset: offset))
        .get();
  }
}

Future<List<Message>> searchMessagesStored(
  String text, {
  required StorageDatabase storage,
}) {
  return storage.searchMessageBodys(text);
}

// example of loading queries separate from database declaration
// import './queries.dart';

///
/// Save Messages (Cold Storage) OLD
///
/// In storage, messages are indexed by eventId
/// In redux, they're indexed by RoomID and placed in a list
///
Future<void> saveMessages(
  List<Message> messages, {
  required Database storage,
}) async {
  final store = StoreRef<String?, String>(StorageKeys.MESSAGES);

  return storage.transaction((txn) async {
    for (final Message message in messages) {
      final record = store.record(message.id);
      await record.put(txn, json.encode(message));
    }
  });
}

///
/// Save Messages (Cold Storage) TODO: NEW
///
/// In storage, messages are indexed by eventId
/// In redux, they're indexed by RoomID and placed in a list
///
Future<void> saveMessagesCold(
  List<Message> messages, {
  required StorageDatabase storage,
}) async {
  await storage.insertMessagesBatched(messages);
}

///
/// Load Messages (Cold Storage)
///
/// In storage, messages are indexed by eventId
/// In redux, they're indexed by RoomID and placed in a list
///
Future<List<Message>> loadMessages(
  List<String> eventIds, {
  required Database storage,
  int offset = 0,
  int limit = 20, // default amount loaded
}) async {
  final List<Message> messages = [];

  try {
    final store = StoreRef<String?, String>(StorageKeys.MESSAGES);

    // TODO: properly paginate through cold storage messages instead of loading all
    final messageIds = eventIds; //.skip(offset).take(limit).toList();

    final messagesPaginated = await store.records(messageIds).get(storage);

    for (final String? message in messagesPaginated) {
      if (message != null) {
        messages.add(Message.fromJson(json.decode(message)));
      }
    }

    return messages;
  } catch (error) {
    printError(error.toString(), title: 'loadMessages');
    return [];
  }
}

Future<List<Message>> loadMessagesCold(
  List<String> eventIds, {
  required StorageDatabase storage,
  int offset = 0,
  int limit = 25, // default amount loaded
}) async {
  try {
    return storage.selectMessages(eventIds, offset: offset, limit: limit);
  } catch (error) {
    printError(error.toString(), title: 'loadMessages');
    return [];
  }
}
