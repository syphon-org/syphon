// Project imports:
import './actions.dart';
import './state.dart';

CryptoStore cryptoReducer(
    [CryptoStore state = const CryptoStore(), dynamic action]) {
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
    case SetOneTimeKeysClaimed:
      return state.copyWith(
        oneTimeKeysClaimed: action.oneTimeKeys,
      );
    case AddOutboundKeySession:
      final outboundSessions = Map<String, String>.from(
        state.outboundKeySessions,
      );

      outboundSessions.putIfAbsent(action.identityKey, () => action.session);

      return state.copyWith(
        outboundKeySessions: outboundSessions,
      );
    case AddInboundKeySession:
      final inboundKeySessions = Map<String, String>.from(
        state.inboundKeySessions,
      );

      inboundKeySessions.putIfAbsent(action.identityKey, () => action.session);

      return state.copyWith(
        inboundKeySessions: inboundKeySessions,
      );
    case AddOutboundMessageSession:
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
    case AddInboundMessageSession:
      final messageSessionIndex = Map<String, Map<String, int>>.from(
        state.messageSessionIndexNEW ?? {},
      );

      final messageSessionsInbound = Map<String, Map<String, String>>.from(
        state.inboundMessageSessions ?? {},
      );

      // safety functions to catch newly cached store
      messageSessionIndex.putIfAbsent(action.roomId, () => Map<String, int>());
      messageSessionsInbound.putIfAbsent(
        action.roomId,
        () => Map<String, String>(),
      );

      // add or update inbound message session by roomId + identity
      final Map<String, String> messageSessionInboundNew = {
        action.identityKey: action.session
      };

      messageSessionsInbound[action.roomId].addAll(messageSessionInboundNew);

      // add or update inbound message index by roomId + identity
      final Map<String, int> messageSessionIndexUpdated = {
        action.identityKey: action.messageIndex
      };

      messageSessionIndex[action.roomId].addAll(messageSessionIndexUpdated);

      return state.copyWith(
        messageSessionIndexNEW: messageSessionIndex,
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
