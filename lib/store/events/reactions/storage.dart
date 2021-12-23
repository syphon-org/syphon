import 'dart:async';

import 'package:drift/drift.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/database.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/redaction/model.dart';

///
/// Reaction Queries - unencrypted (Cold Storage)
///
/// In storage, reactions are indexed by eventId
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
  /// Select Reactions (Ids)
  ///
  /// Query every message known in a room
  ///
  Future<List<Reaction>> selectReactionsById(List<String> reactionIds) {
    return (select(reactions)..where((tbl) => tbl.body.isNotNull() & tbl.id.isIn(reactionIds)))
        .get();
  }

  ///
  /// Select Reactions (All)
  ///
  /// Query every message known in a room
  ///
  Future<List<Reaction>> selectReactionsPerEvent(String roomId, List<String>? eventIds) {
    return (select(reactions)
          ..where((tbl) =>
              tbl.body.isNotNull() &
              tbl.roomId.equals(roomId) &
              tbl.relEventId.isIn(eventIds ?? [])))
        .get();
  }
}

Future<void> saveReactions(
  List<Reaction> reactions, {
  required StorageDatabase storage,
}) async {
  await storage.insertReactionsBatched(reactions);
}

Future<void> saveReactionsRedacted(
  List<Redaction> redactions, {
  required StorageDatabase storage,
}) async {
  final reactionIds = redactions.map((redaction) => redaction.redactId ?? '').toList();
  final reactions = await storage.selectReactionsById(reactionIds);

  final reactionsUpdated = reactions.map((reaction) => reaction.copyWith(body: null)).toList();
  await storage.insertReactionsBatched(reactionsUpdated);
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
    printError(error.toString(), title: 'loadReactions');
    return [];
  }
}

///
/// Load Reactions Mapped
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
    printError(error.toString(), title: 'loadReactions');
    return {};
  }
}
