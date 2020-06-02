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
    default:
      return state;
  }
}
