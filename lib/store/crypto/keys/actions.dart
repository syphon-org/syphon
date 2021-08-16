import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/store/alerts/actions.dart';
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
  required Message event,
  required String roomId,
}) {
  return (Store<AppState> store) async {
    try {
      final String deviceId = event.deviceId ?? '';
      final String senderKey = event.senderKey ?? '';
      final String sessionId = event.sessionId ?? '';

      // Just needs to be unique, but different
      final requestId = sha1.convert(utf8.encode(sessionId)).toString();

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
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        origin: 'sendKeyRequest',
      ));
      return const {};
    }
  };
}
