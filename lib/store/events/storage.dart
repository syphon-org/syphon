import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/events/model.dart';

const String MESSAGES = 'messages';

Future<void> saveMessages(
  List<Message> messages, {
  Database storage,
}) async {
  final store = StoreRef<String, String>(MESSAGES);

  await storage.transaction((txn) async {
    for (Message message in messages) {
      final record = store.record(message.id);
      await record.put(txn, json.encode(message));
    }
  });
}

/**
 * Load Messages (Cold Storage)
 * 
 * In storage, messages are indexed by eventId
 * In redux, they're indexed by RoomID and placed in a list
 */
Future<List<Message>> loadMessages(
  List<String> eventIds, {
  Database storage,
  bool encrypted,
  int offset = 0,
  int limit = 20, // default amount loaded
}) async {
  final List<Message> messages = [];

  try {
    final store = StoreRef<String, String>(MESSAGES);

    final eventIdsPaginated = eventIds.skip(offset).take(limit).toList();

    final messagesPaginated =
        await store.records(eventIdsPaginated).get(storage);

    for (String message in messagesPaginated) {
      messages.add(Message.fromJson(json.decode(message)));
    }

    printDebug('[messages] loaded ${messages.length.toString()}');
    return messages;
  } catch (error) {
    printDebug(error.toString(), title: 'loadMessages');
    return null;
  }
}
