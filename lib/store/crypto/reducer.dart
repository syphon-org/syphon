import 'dart:typed_data';

import './state.dart';
import './actions.dart';

CryptoStore cryptoReducer(
    [CryptoStore state = const CryptoStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetDeviceKeys:
      return state.copyWith(
        deviceKeys: action.deviceKeys,
      );
    case SetDeviceKeysOwned:
      return state.copyWith(
        deviceKeysOwned: action.deviceKeysOwned,
      );
    case ToggleDeviceKeysExist:
      return state.copyWith(
        deviceKeysExist: action.existence,
      );
    default:
      return state;
  }
}
