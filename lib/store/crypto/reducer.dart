import './state.dart';
import './actions.dart';

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

      outboundMessageSessions.putIfAbsent(action.roomId, () => action.session);

      return state.copyWith(
        outboundMessageSessions: outboundMessageSessions,
      );
    case AddInboundMessageSession:
      final messageSessionIndex =
          Map<String, int>.from(state.messageSessionIndex);

      final inboundMessageSessions = Map<String, Map<String, String>>.from(
          state.inboundMessageSessions ?? {});

      inboundMessageSessions.putIfAbsent(
        action.roomId,
        () => Map<String, String>(),
      );

      // Add new inbound message session by roomId + identity
      final Map<String, String> messageSessionInboundNew = {
        action.identityKey: action.session
      };
      inboundMessageSessions[action.roomId].addAll(messageSessionInboundNew);

      // Add new index
      messageSessionIndex[action.roomId] = action.messageIndex;

      return state.copyWith(
        inboundMessageSessions: inboundMessageSessions,
        messageSessionIndex: messageSessionIndex,
      );

    case ToggleDeviceKeysExist:
      return state.copyWith(
        deviceKeysExist: action.existence,
      );
    case ResetDeviceKeys:
      return state.copyWith(
        outboundMessageSessions: Map<String, Map<String, String>>(),
        inboundMessageSessions: Map<String, Map<String, String>>(),
      );

    default:
      return state;
  }
}
