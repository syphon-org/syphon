import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/events/ephemeral/m.read/model.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/reactions/model.dart';

const String EVENTS = 'events';
const String MESSAGES = 'messages';
const String RECEIPTS = 'receipts';
const String REACTIONS = 'reactions';

Future<void> saveEvents(
  List<Event> events, {
  Database storage,
}) async {
  final store = StoreRef<String, String>(EVENTS);

  return await storage.transaction((txn) async {
    for (Event event in events) {
      final record = store.record(event.id);
      await record.put(txn, json.encode(event));
    }
  });
}

Future<void> saveReactions(
  List<Reaction> reactions, {
  Database storage,
}) async {
  final store = StoreRef<String, String>(REACTIONS);

  return await storage.transaction((txn) async {
    for (Reaction reaction in reactions) {
      final record = store.record(reaction.id);
      await record.put(txn, json.encode(reaction));
    }
  });
}

Future<void> saveMessages(
  List<Message> messages, {
  Database storage,
}) async {
  final store = StoreRef<String, String>(MESSAGES);

  return await storage.transaction((txn) async {
    for (Message message in messages) {
      final record = store.record(message.id);
      await record.put(txn, json.encode(message));
    }
  });
}

Future<void> saveReceipts(
  Map<String, ReadStatus> receipts, {
  Database storage,
}) async {
  final store = StoreRef<String, String>(RECEIPTS);

  return await storage.transaction((txn) async {
    for (String roomId in receipts.keys) {
      final record = store.record(roomId);
      await record.put(txn, json.encode(receipts[roomId]));
    }
  });
}

Future<Message> loadMessage(String eventId, {Database storage}) async {
  final store = StoreRef<String, String>(MESSAGES);

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
  bool encrypted,
  int offset = 0,
  int limit = 20, // default amount loaded
}) async {
  final List<Message> messages = [];

  try {
    final store = StoreRef<String, String>(MESSAGES);

    // TODO: properly paginate through cold storage messages instead of loading all
    final eventIdsPaginated =
        eventIds ?? []; //.skip(offset).take(limit).toList();

    final messagesPaginated =
        await store.records(eventIdsPaginated).get(storage);

    for (String message in messagesPaginated) {
      messages.add(Message.fromJson(json.decode(message)));
    }

    return messages;
  } catch (error) {
    printError(error.toString(), title: 'loadMessages');
    return null;
  }
}
