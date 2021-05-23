import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/crypto/model.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/index.dart';

///
///
/// Send Key Request
///
/// allow users to request keys or automatically send
/// at least one if an event cannot be decrypted
///
ThunkAction<AppState> sendKeyRequest({
  required String roomId,
  required Message message,
  required DeviceKey deviceKey,
}) {
  return (Store<AppState> store) async {
    try {
      final deviceKeys = store.state.cryptoStore.deviceKeys;

      final data = await MatrixApi.requestKeys(
        protocol: store.state.authStore.protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        roomId: roomId,
        userId: deviceKey.userId,
        deviceId: deviceKey.deviceId,
        senderKey: message.senderKey,
        sessionId: message.sessionId,
      );
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        origin: 'fetchDeviceKeys',
      ));
      return const {};
    }
  };
}
