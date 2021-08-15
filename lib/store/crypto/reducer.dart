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
    case AddOutboundKeySession:
      final _action = action as AddOutboundKeySession;
      final outboundSessions = Map<String, String>.from(
        state.outboundKeySessions,
      );

      outboundSessions.putIfAbsent(_action.identityKey, () => _action.session);

      return state.copyWith(
        outboundKeySessions: outboundSessions,
      );
    case AddInboundKeySession:
      final _action = action as AddInboundKeySession;
      final inboundKeySessions = Map<String, String>.from(
        state.inboundKeySessions,
      );

      inboundKeySessions.putIfAbsent(_action.identityKey, () => _action.session);

      return state.copyWith(
        inboundKeySessions: inboundKeySessions,
      );
    case AddOutboundMessageSession:
      final _action = action as AddOutboundMessageSession;
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
    case AddInboundMessageSession:
      final _action = action as AddInboundMessageSession;

      final messageSessionIndex = Map<String, Map<String, int>>.from(
        state.messageSessionIndex,
      );

      final messageSessionsInbound = Map<String, Map<String, String>>.from(
        state.inboundMessageSessions,
      );

      // safety functions to catch newly cached store
      messageSessionIndex.putIfAbsent(_action.roomId, () => <String, int>{});
      messageSessionsInbound.putIfAbsent(action.roomId, () => <String, String>{});

      // add or update inbound message session by roomId + identity
      final Map<String, String> messageSessionInboundNew = {_action.identityKey: _action.session};

      messageSessionsInbound[_action.roomId]!.addAll(messageSessionInboundNew);

      // add or update inbound message index by roomId + identity
      final Map<String, int> messageSessionIndexUpdated = {_action.identityKey: _action.messageIndex};

      messageSessionIndex[action.roomId]!.addAll(messageSessionIndexUpdated);

      return state.copyWith(
        messageSessionIndex: messageSessionIndex,
        inboundMessageSessions: messageSessionsInbound,
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
