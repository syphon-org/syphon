import 'dart:async';
import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart'; 
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/redaction/model.dart';
 
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
      for (final Redaction redaction in redactions) {
        final record = store.record(redaction.redactId);
        await record.put(txn, json.encode(redaction));
      }
    });
  } catch (error) {
    printError('[saveRedactions] $error');
    rethrow;
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

  final redactions = <String, Redaction>{};

  final redactionsData = await store.find(storage);

  for (final RecordSnapshot<String, String> record in redactionsData) {
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
      for (final Reaction reaction in reactions) {
        if (reaction.relEventId != null) {
          final record = store.record(reaction.relEventId);
          final exists = await record.exists(storage);

          var reactionsUpdated = [reaction];

          if (exists) {
            final existingRaw = await record.get(storage);
            final existingJson = List.from(await json.decode(existingRaw!));
            final existingList = List.from(existingJson.map(
              (json) => Reaction.fromJson(json),
            ));

            final exists = existingList.any(
              (existing) => existing.id == reaction.id,
            );

            if (!exists) {
              reactionsUpdated = [...existingList, reaction];
            }
          }

          await record.put(txn, json.encode(reactionsUpdated));
        }
      }
    });
  } catch (error) {
    printError('[saveReactions] $error');
    rethrow;
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
    final reactionsMap = <String, List<Reaction>>{};
    final reactionsRecords = await store.records(messageIds).getSnapshots(storage);

    for (final RecordSnapshot<String?, String>? reactionList in reactionsRecords) {
      if (reactionList != null) {
        final reactions =
            List.from(await json.decode(reactionList.value)).map((json) => Reaction.fromJson(json)).toList();
        reactionsMap.putIfAbsent(reactionList.key!, () => reactions);
      }
    }

    return reactionsMap;
  } catch (error) {
    printError(error.toString());
    return {};
  }
}
