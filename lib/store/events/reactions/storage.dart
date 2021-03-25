import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/store/events/reactions/model.dart';

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
  Database storage,
}) async {
  try {
    final store = StoreRef<String, String>(StorageKeys.REACTIONS);

    return await storage.transaction((txn) async {
      for (Reaction reaction in reactions) {
        if (reaction.relEventId != null) {
          final record = store.record(reaction.relEventId);
          final exists = await record.exists(storage);

          var reactionsUpdated = [reaction];

          if (exists) {
            final existingRaw = await record.get(storage);
            final existingJson = List.from(await json.decode(existingRaw));
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
  List<String> messageIds, {
  Database storage,
}) async {
  try {
    final store = StoreRef<String, String>(StorageKeys.REACTIONS);
    final reactionsMap = Map<String, List<Reaction>>();
    final reactionsRecords =
        await store.records(messageIds).getSnapshots(storage);

    for (RecordSnapshot<String, String> reactionList
        in reactionsRecords ?? []) {
      if (reactionList != null) {
        final reactions = List.from(await json.decode(reactionList.value))
            .map((json) => Reaction.fromJson(json))
            .toList();
        reactionsMap.putIfAbsent(reactionList.key, () => reactions);
      }
    }

    return reactionsMap;
  } catch (error) {
    printError(error);
    return Map();
  }
}
