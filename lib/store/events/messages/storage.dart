import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/store/events/messages/model.dart';

Future<void> saveMessages(
  List<Message> messages, {
  Database storage,
}) async {
  final store = StoreRef<String, String>(StorageKeys.MESSAGES);

  return await storage.transaction((txn) async {
    for (Message message in messages) {
      final record = store.record(message.id);
      await record.put(txn, json.encode(message));
    }
  });
}

Future<Message> loadMessage(String eventId, {Database storage}) async {
  final store = StoreRef<String, String>(StorageKeys.MESSAGES);

  final message = await store.record(eventId).get(storage);

  return Message.fromJson(json.decode(message));
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
  int offset = 0,
  int limit = 20, // default amount loaded
}) async {
  final List<Message> messages = [];

  try {
    final store = StoreRef<String, String>(StorageKeys.MESSAGES);

    // TODO: properly paginate through cold storage messages instead of loading all
    final messageIds = eventIds ?? []; //.skip(offset).take(limit).toList();

    final messagesPaginated = await store.records(messageIds).get(storage);

    for (String message in messagesPaginated) {
      messages.add(Message.fromJson(json.decode(message)));
    }

    return messages;
  } catch (error) {
    printError(error.toString(), tag: 'loadMessages');
    return List();
  }
}
