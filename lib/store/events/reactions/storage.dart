import 'dart:async';

import 'package:drift/drift.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/drift/database.dart';
import 'package:syphon/store/events/reactions/model.dart';

///
/// Reaction Queries - unencrypted (Cold Storage)
///
/// In storage, messages are indexed by eventId
/// In redux, they're indexed by RoomID and placed in a list
///
extension ReactionQueries on StorageDatabase {
  Future<void> insertReactionsBatched(List<Reaction> reactions) {
    return batch(
      (batch) => batch.insertAllOnConflictUpdate(
        this.reactions,
        reactions,
      ),
    );
  }

  ///
  /// Select Reactions (All)
  ///
  /// Query every message known in a room
  ///
  Future<List<Reaction>> selectReactionsPerEvent(String roomId, List<String>? eventIds) {
    return (select(reactions)
          ..where((tbl) => tbl.roomId.equals(roomId) & tbl.relEventId.isIn(eventIds ?? [])))
        .get();
  }
}

Future<void> saveReactions(
  List<Reaction> reactions, {
  required StorageDatabase storage,
}) async {
  await storage.insertReactionsBatched(reactions);
}

///
/// Load Reactions
///
///
Future<List<Reaction>> loadReactions({
  required StorageDatabase storage,
  required String roomId,
  List<String> eventIds = const [],
}) async {
  try {
    return storage.selectReactionsPerEvent(roomId, eventIds);
  } catch (error) {
    printError(error.toString(), title: 'loadMessages');
    return [];
  }
}

///
/// Load Reactions
///
///
Future<Map<String, List<Reaction>>> loadReactionsMapped({
  required StorageDatabase storage,
  required String roomId,
  List<String> eventIds = const [],
}) async {
  try {
    final reactions = await storage.selectReactionsPerEvent(roomId, eventIds);

    return Map<String, List<Reaction>>.fromIterable(
      reactions,
      key: (reaction) => reaction.relEventId,
      value: (reaction) => reactions
          .where(
            (r) => r.relEventId == reaction.relEventId,
          )
          .toList(),
    );
  } catch (error) {
    printError(error.toString(), title: 'loadMessages');
    return {};
  }
}
