import 'dart:typed_data';

import 'package:syphon/store/crypto/model.dart';

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
    case ToggleDeviceKeysExist:
      return state.copyWith(
        deviceKeysExist: action.existence,
      );
    case ResetDeviceKeys:
      return state.copyWith(
        deviceKeysOwned: Map<String, DeviceKey>(),
        inboundMessageSessions: Map<String, String>(),
        outboundMessageSessions: Map<String, String>(),
        inboundKeySessions: Map<String, String>(), // one-time device keys
        outboundKeySessions: Map<String, String>(), // one-time device keys
      );
    default:
      return state;
  }
}
