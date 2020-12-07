import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/events/model.dart';

const String MESSAGES = 'messages';

Future<void> saveMessages(
  List<Message> messages, {
  Database cache,
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

Future<Map<String, Message>> loadMessages({
  List<String> eventIds,
  bool encrypted,
  Database cache,
  Database storage,
  int offset = 0,
  int page = 20, // default amount loaded
  int limit,
}) async {
  final Map<String, Message> messages = {};

  try {
    final store = StoreRef<String, String>(MESSAGES);
    final count = limit ?? await store.count(storage);

    final finder = Finder(
      limit: page,
      offset: offset,
    );

    final messagesPaginated = await store.find(
      storage,
      finder: finder,
    );

    if (messagesPaginated.isEmpty) {
      return messages;
    }

    for (RecordSnapshot<String, String> record in messagesPaginated) {
      messages[record.key] = Message.fromJson(json.decode(record.value));
    }

    if (offset < count) {
      messages.addAll(await loadMessages(
        offset: offset + limit,
        storage: storage,
      ));
    }
  } catch (error) {
    printDebug(error.toString());
  }
  printDebug('[messages] loaded ${messages.length.toString()}');
  return messages;
}
