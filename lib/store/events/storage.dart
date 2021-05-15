import 'dart:async';
import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:syphon/global/algos.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/store/events/ephemeral/m.read/model.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/redaction/model.dart';

Future<void> saveEvents(
  List<Event> events, {
  required Database storage,
}) async {
  final store = StoreRef<String?, String>(StorageKeys.EVENTS);

  return await storage.transaction((txn) async {
    for (Event event in events) {
      final record = store.record(event.id);
      await record.put(txn, json.encode(event));
    }
  });
}

Future<void> deleteEvents(
  List<Event> events, {
  Database? storage,
}) async {
  final stores = [
    StoreRef<String?, String>(StorageKeys.MESSAGES),
    StoreRef<String?, String>(StorageKeys.REACTIONS),
  ];

  await Future.wait(stores.map((store) async {
    return await storage!.transaction((txn) async {
      for (Event event in events) {
        final record = store.record(event.id);
        await record.delete(storage);
      }
    });
  }));
}

///
/// Save Redactions
///
/// Saves redactions to a map keyed by
/// event ids of redacted events
///
Future<void> saveRedactions(
  List<Redaction> redactions, {
  required Database storage,
}) async {
  try {
    final store = StoreRef<String?, String>(StorageKeys.REDACTIONS);

    return await storage.transaction((txn) async {
      for (Redaction redaction in redactions) {
        final record = store.record(redaction.redactId);
        await record.put(txn, json.encode(redaction));
      }
    });
  } catch (error) {
    printError('[saveRedactions] $error');
    throw error;
  }
}

///
/// Load Redactions
///
/// Load all the redactions from storage
/// filtering should occur shortly after in
/// another parser/filter/selector
///
Future<Map<String, Redaction>> loadRedactions({
  required Database storage,
}) async {
  final store = StoreRef<String, String>(StorageKeys.REDACTIONS);

  final redactions = Map<String, Redaction>();

  final redactionsData = await store.find(storage);

  for (RecordSnapshot<String, String> record in redactionsData) {
    redactions[record.key] = Redaction.fromJson(
      json.decode(record.value),
    );
  }

  return redactions;
}

///
/// Save Reactions
///
/// Saves reactions to storage by the related/associated message id
/// this allows calls to fetch reactions from cold storage to be
/// O(1) referenced by map keys, also prevents additional key references
/// to the specific reaction in other objects
///
Future<void> saveReactions(
  List<Reaction> reactions, {
  required Database storage,
}) async {
  try {
    final store = StoreRef<String?, String>(StorageKeys.REACTIONS);

    return await storage.transaction((txn) async {
      for (Reaction reaction in reactions) {
        if (reaction.relEventId != null) {
          final record = store.record(reaction.relEventId);
          final exists = await record.exists(storage);

          var reactionsUpdated = [reaction];

          if (exists) {
            final existingRaw = await (record.get(storage) as FutureOr<String>);
            final existingJson = List.from(await json.decode(existingRaw));
            final existingList = List.from(existingJson.map(
              (json) => Reaction.fromJson(json),
            ));

            final exists = existingList.any(
              (existing) => existing.id == reaction.id,
            );

            if (!exists) {
              reactionsUpdated = [
                ...existingList as Iterable<Reaction>,
                reaction
              ];
            }
          }

          await record.put(txn, json.encode(reactionsUpdated));
        }
      }
    });
  } catch (error) {
    printError('[saveReactions] $error');
    throw error;
  }
}

///
/// Load Reactions
///
/// Loads reactions from storage by the related/associated message id
/// this done with O(1) by reference with message ids being the key
///
Future<Map<String, List<Reaction>>> loadReactions(
  List<String?> messageIds, {
  required Database storage,
}) async {
  try {
    final store = StoreRef<String?, String>(StorageKeys.REACTIONS);
    final reactionsMap = Map<String, List<Reaction>>();
    final reactionsRecords =
        await (store.records(messageIds).getSnapshots(storage)
            as FutureOr<List<RecordSnapshot<String, String>>>);

    for (RecordSnapshot<String, String> reactionList in reactionsRecords) {
      final reactions = List.from(await json.decode(reactionList.value))
          .map((json) => Reaction.fromJson(json))
          .toList();
      reactionsMap.putIfAbsent(reactionList.key, () => reactions);
    }

    return reactionsMap;
  } catch (error) {
    printError(error.toString());
    return Map();
  }
}

Future<void> saveMessages(
  List<Message> messages, {
  required Database storage,
}) async {
  final store = StoreRef<String?, String>(StorageKeys.MESSAGES);

  return await storage.transaction((txn) async {
    for (Message message in messages) {
      final record = store.record(message.id);
      await record.put(txn, json.encode(message));
    }
  });
}

Future<Message> loadMessage(String eventId, {required Database storage}) async {
  final store = StoreRef<String, String>(StorageKeys.MESSAGES);

  final message =
      await (store.record(eventId).get(storage) as FutureOr<String>);

  return Message.fromJson(json.decode(message));
}

/**
 * Load Messages (Cold Storage)
 * 
 * In storage, messages are indexed by eventId
 * In redux, they're indexed by RoomID and placed in a list
 */
Future<List<Message>> loadMessages(
  List<String?> eventIds, {
  required Database storage,
  int offset = 0,
  int limit = 20, // default amount loaded
}) async {
  final List<Message> messages = [];

  try {
    final store = StoreRef<String?, String>(StorageKeys.MESSAGES);

    // TODO: properly paginate through cold storage messages instead of loading all
    final messageIds = eventIds; //.skip(offset).take(limit).toList();

    final messagesPaginated = await (store.records(messageIds).get(storage)
        as FutureOr<List<String>>);

    for (String message in messagesPaginated) {
      messages.add(Message.fromJson(json.decode(message)));
    }

    return messages;
  } catch (error) {
    printError(error.toString(), title: 'loadMessages');
    return [];
  }
}
