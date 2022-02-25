import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/storage/database.dart';
import 'package:syphon/store/crypto/sessions/model.dart' as model;
import 'package:syphon/store/crypto/state.dart';

///
/// Auth Quesies - unencrypted (Cold Storage)
///
/// In storage, messages are indexed by eventId
/// In redux, they're indexed by RoomID and placed in a list
///
extension CryptoQueries on StorageDatabase {
  Future<int> insertCryptoStore(CryptoStore store) async {
    final storeJson = json.decode(json.encode(store));

    return into(cryptos).insertOnConflictUpdate(CryptosCompanion(
      id: Value(StorageKeys.CRYPTO),
      store: Value(storeJson),
    ));
  }

  Future<CryptoStore?> selectCryptoStore() async {
    final row = await (select(cryptos)..where((tbl) => tbl.id.isNotNull())).getSingleOrNull();

    if (row == null) {
      return null;
    }

    return CryptoStore.fromJson(row.store ?? {});
  }

  Future<void> insertMessageSessions(List<MessageSession> sessions) async {
    return batch(
      (batch) => batch.insertAllOnConflictUpdate(
        messageSessions,
        sessions,
      ),
    );
  }

  Future<List<MessageSession>> selectMessageSessionsInbound(List<String> roomIds) {
    return (select(messageSessions)
          ..where((tbl) => tbl.roomId.isIn(roomIds) & tbl.inbound.equals(true)))
        .get();
  }

  Future<List<MessageSession>> selectMessageSessionsInboundAll() {
    return (select(messageSessions)..where((tbl) => tbl.inbound.equals(true))).get();
  }
}

Future<int> saveCrypto(
  CryptoStore store, {
  required StorageDatabase storage,
}) async {
  return storage.insertCryptoStore(store);
}

///
/// Load Crypto Store (Cold Storage)
///
Future<CryptoStore?> loadCrypto({required StorageDatabase storage}) async {
  try {
    return storage.selectCryptoStore();
  } catch (error) {
    printError(error.toString(), title: 'loadCrypto');
    return null;
  }
}

Future<void> saveMessageSessionInbound({
  required String roomId,
  required String identityKey,
  required String session,
  required StorageDatabase storage,
}) async {
  return storage.insertMessageSessions([
    MessageSession(
      id: session,
      roomId: roomId,
      session: session,
      identityKey: identityKey,
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
            roomId: roomId,
            session: session.serialized,
            identityKey: identityKey,
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
        index: 0,
        serialized: session.session, // already pickled
        createdAt: DateTime.now().millisecondsSinceEpoch,
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
    printError(error.toString(), title: 'loadCrypto');
    return {};
  }
}
