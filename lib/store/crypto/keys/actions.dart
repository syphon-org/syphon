import 'package:crypt/crypt.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/index.dart';

///
///
/// Send Key Request
///
/// allow users to request keys or automatically send
/// at least one if an event cannot be decrypted
///
ThunkAction<AppState> sendKeyRequest({
  required Event event,
  required String roomId,
}) {
  return (Store<AppState> store) async {
    try {
      final String deviceId = event.content['device_id'];
      final String senderKey = event.content['sender_key'];
      final String sessionId = event.content['session_id'];

      // Just needs to be unique, but different
      final requestId = Crypt.sha256(sessionId, rounds: 1000, salt: '').hash;

      final currentUser = store.state.authStore.user;

      final data = await MatrixApi.requestKeys(
        protocol: store.state.authStore.protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        roomId: roomId,
        userId: event.sender,
        deviceId: deviceId,
        senderKey: senderKey,
        sessionId: sessionId,
        requestId: requestId,
        requestingUserId: currentUser.userId,
        requestingDeviceId: currentUser.deviceId,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      printDebug('[sendKeyRequest] COMPLETED');
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        origin: 'sendKeyRequest',
      ));
      return const {};
    }
  };
}
