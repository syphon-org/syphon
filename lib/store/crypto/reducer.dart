import 'package:syphon/store/crypto/keys/actions.dart';
import 'package:syphon/store/crypto/sessions/actions.dart';
import 'package:syphon/store/crypto/sessions/model.dart';

import './actions.dart';
import './state.dart';

CryptoStore cryptoReducer([CryptoStore state = const CryptoStore(), dynamic actionAny]) {
  switch (actionAny.runtimeType) {
    case SetOlmAccount:
      return state.copyWith(
        olmAccount: actionAny.olmAccount,
      );
    case SetOlmAccountBackup:
      return state.copyWith(
        olmAccountKey: actionAny.olmAccountKey,
      );
    case SetDeviceKeys:
      return state.copyWith(
        deviceKeys: actionAny.deviceKeys,
      );
    case SetDeviceKeysOwned:
      return state.copyWith(
        deviceKeysOwned: actionAny.deviceKeysOwned,
      );
    case SetOneTimeKeysCounts:
      return state.copyWith(
        oneTimeKeysCounts: actionAny.oneTimeKeysCounts,
      );
    case SetOneTimeKeysStable:
      final action = actionAny as SetOneTimeKeysStable;
      return state.copyWith(
        oneTimeKeysStable: action.stable,
      );
    case SetOneTimeKeysClaimed:
      return state.copyWith(
        oneTimeKeysClaimed: actionAny.oneTimeKeys,
      );
    case AddKeySession:
      final action = actionAny as AddKeySession;

      final keySessions = Map<String, Map<String, String>>.from(
        state.keySessions,
      );

      final sessionId = action.sessionId;
      final sessionNew = action.session;

      // Update sessions by their ID for a certain identityKey (sender_key)
      keySessions.update(
        action.identityKey,
        (session) => session
          ..update(
            sessionId,
            (value) => sessionNew,
            ifAbsent: () => sessionNew,
          ),
        ifAbsent: () => {sessionId: sessionNew},
      );

      return state.copyWith(
        keySessions: keySessions,
      );
    case AddMessageSessionOutbound:
      final action = actionAny as AddMessageSessionOutbound;
      final outboundMessageSessions = Map<String, String>.from(
        state.outboundMessageSessions,
      );

      outboundMessageSessions.update(
        action.roomId,
        (sessionCurrent) => action.session,
        ifAbsent: () => action.session,
      );

      return state.copyWith(
        outboundMessageSessions: outboundMessageSessions,
      );
    case AddMessageSessionInbound:
      final action = actionAny as AddMessageSessionInbound;

      final roomId = action.roomId;
      final senderKey = action.senderKey;
      final sessionNew = action.session;
      final messageIndex = action.messageIndex;

      final messageSessions = Map<String, Map<String, List<MessageSession>>>.from(
        state.messageSessionsInbound,
      );

      final messageSessionNew = MessageSession(
        index: messageIndex,
        serialized: sessionNew, // already pickled
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

      return state.copyWith(
        messageSessionsInbound: messageSessions,
      );

    // TODO: make this work synchronously?? [combineMessageSesssions](./converters.dart)
    case AddMessageSessionsInbound:
      final action = actionAny as AddMessageSessionsInbound;

      final messageSessionsNew = action.sessions;

      final messageSessionsExisting = Map<String, Map<String, List<MessageSession>>>.from(
        state.messageSessionsInbound,
      );

      // prepend session keys to an array per spec
      for (final roomSessions in messageSessionsNew.entries) {
        final roomId = roomSessions.key;
        final sessions = roomSessions.value;

        for (final messsageSessions in sessions.entries) {
          final senderKey = messsageSessions.key;
          final sessionsSerialized = messsageSessions.value;

          for (final session in sessionsSerialized) {
            messageSessionsExisting.update(
              roomId,
              (identitySessions) => identitySessions
                ..update(
                  senderKey,
                  (sessions) => sessions.toList()..insert(0, session),
                  ifAbsent: () => [session],
                ),
              ifAbsent: () => {
                senderKey: [session],
              },
            );
          }
        }
      }

      return state.copyWith(
        messageSessionsInbound: messageSessionsExisting,
      );
    case SetMessageSessionsInbound:
      final action = actionAny as SetMessageSessionsInbound;

      return state.copyWith(
        messageSessionsInbound: action.sessions,
      );
    case ToggleDeviceKeysExist:
      return state.copyWith(
        deviceKeysExist: actionAny.existence,
      );
    case ResetCrypto:
      return CryptoStore();
    default:
      return state;
  }
}
