import 'package:syphon/store/crypto/keys/actions.dart';
import 'package:syphon/store/crypto/sessions/actions.dart';
import 'package:syphon/store/crypto/sessions/model.dart';

import './actions.dart';
import './state.dart';

CryptoStore cryptoReducer([CryptoStore state = const CryptoStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetOlmAccount:
      return state.copyWith(
        olmAccount: action.olmAccount,
      );
    case SetOlmAccountBackup:
      return state.copyWith(
        olmAccountKey: action.olmAccountKey,
      );
    case SetDeviceKeys:
      return state.copyWith(
        deviceKeys: action.deviceKeys,
      );
    case SetDeviceKeysOwned:
      return state.copyWith(
        deviceKeysOwned: action.deviceKeysOwned,
      );
    case SetOneTimeKeysCounts:
      return state.copyWith(
        oneTimeKeysCounts: action.oneTimeKeysCounts,
      );
    case SetOneTimeKeysStable:
      final _action = action as SetOneTimeKeysStable;
      return state.copyWith(
        oneTimeKeysStable: _action.stable,
      );
    case SetOneTimeKeysClaimed:
      return state.copyWith(
        oneTimeKeysClaimed: action.oneTimeKeys,
      );
    case AddKeySession:
      final _action = action as AddKeySession;

      final keySessions = Map<String, Map<String, String>>.from(
        state.keySessions,
      );

      final sessionId = _action.sessionId;
      final sessionNew = _action.session;

      // Update sessions by their ID for a certain identityKey (sender_key)
      keySessions.update(
        _action.identityKey,
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
      final _action = action as AddMessageSessionOutbound;
      final outboundMessageSessions = Map<String, String>.from(
        state.outboundMessageSessions,
      );

      outboundMessageSessions.update(
        _action.roomId,
        (sessionCurrent) => _action.session,
        ifAbsent: () => _action.session,
      );

      return state.copyWith(
        outboundMessageSessions: outboundMessageSessions,
      );
    case AddMessageSessionInbound:
      final _action = action as AddMessageSessionInbound;

      final roomId = _action.roomId;
      final senderKey = _action.senderKey;
      final sessionNew = _action.session;
      final messageIndex = _action.messageIndex;

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
      final _action = action as AddMessageSessionsInbound;

      final messageSessionsNew = _action.sessions;

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
      final _action = action as SetMessageSessionsInbound;

      return state.copyWith(
        messageSessionsInbound: _action.sessions,
      );
    case ToggleDeviceKeysExist:
      return state.copyWith(
        deviceKeysExist: action.existence,
      );
    case ResetCrypto:
      return CryptoStore();
    default:
      return state;
  }
}
