import 'dart:io';

import 'package:drift/drift.dart';
import 'package:syphon/domain/crypto/sessions/model.dart' as model;
import 'package:syphon/global/libs/storage/database.dart';
import 'package:syphon/global/print.dart';

///
/// Auth Quesies - unencrypted (Cold Storage)
///
/// In storage, messages are indexed by eventId
/// In redux, they're indexed by RoomID and placed in a list
///
extension SessionQueries on StorageDatabase {
  Future<void> insertMessageSessions(List<MessageSession> sessions) async {
    // HACK: temporary to account for sqlite versions without UPSERT
    if (Platform.isLinux) {
      return batch(
        (batch) => batch.insertAll(
          messageSessions,
          sessions,
          mode: InsertMode.insertOrReplace,
        ),
      );
    }
    return batch(
      (batch) => batch.insertAllOnConflictUpdate(
        messageSessions,
        sessions,
      ),
    );
  }

  Future<List<MessageSession>> selectMessageSessionsInbound(List<String> roomIds) {
    return (select(messageSessions)
          ..where((tbl) => tbl.roomId.isIn(roomIds) & tbl.inbound.equals(true))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  Future<List<MessageSession>> selectMessageSessionsInboundAll() {
    return (select(messageSessions)
          ..where((tbl) => tbl.inbound.equals(true))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)]))
        .get();
  }
}

Future<void> saveMessageSessionInbound({
  required String roomId,
  required String identityKey,
  required String session,
  required int messageIndex,
  required StorageDatabase storage,
}) async {
  return storage.insertMessageSessions([
    MessageSession(
      id: session,
      roomId: roomId,
      session: session,
      index: messageIndex,
      identityKey: identityKey,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      inbound: true,
    )
  ]);
}

Future<void> saveMessageSessionsInbound(
  Map<String, Map<String, List<model.MessageSession>>> messageSessions, {
  required StorageDatabase storage,
}) async {
  final List<MessageSession> messageSessionsDb = [];

  // prepend session keys to an array per spec
  for (final roomSessions in messageSessions.entries) {
    final roomId = roomSessions.key;
    final sessions = roomSessions.value;

    for (final messsageSessions in sessions.entries) {
      final identityKey = messsageSessions.key;
      final sessionsSerialized = messsageSessions.value;

      for (final session in sessionsSerialized) {
        messageSessionsDb.add(
          MessageSession(
            id: session.serialized,
            index: session.index,
            roomId: roomId,
            session: session.serialized,
            identityKey: identityKey,
            createdAt: session.createdAt,
            inbound: true,
          ),
        );
      }
    }
  }

  return storage.insertMessageSessions(messageSessionsDb);
}

///
/// Load Crypto Store (Cold Storage)
///
///
Future<Map<String, Map<String, List<model.MessageSession>>>> loadMessageSessionsInbound({
  List<String>? roomIds,
  required StorageDatabase storage,
}) async {
  try {
    final messageSessions = <String, Map<String, List<model.MessageSession>>>{};
    var messageSessionsDb = <MessageSession>[];

    if (roomIds == null || roomIds.isEmpty) {
      messageSessionsDb = await storage.selectMessageSessionsInboundAll();
    } else {
      messageSessionsDb = await storage.selectMessageSessionsInbound(roomIds);
    }

    for (final session in messageSessionsDb) {
      final roomId = session.roomId;
      final senderKey = session.identityKey!;

      final messageSessionNew = model.MessageSession(
        index: session.index,
        serialized: session.session, // already pickled
        createdAt: session.createdAt,
      );

      // new message session updates
      messageSessions.update(
        roomId,
        (identitySessions) => identitySessions
          ..update(
            senderKey,
            (sessions) => sessions..insert(0, messageSessionNew),
            ifAbsent: () => [messageSessionNew],
          ),
        ifAbsent: () => {
          senderKey: [messageSessionNew],
        },
      );
    }

    return messageSessions;
  } catch (error) {
    log.error(error.toString(), title: 'loadCrypto');
    return {};
  }
}
