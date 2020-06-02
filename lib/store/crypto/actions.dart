/**
 * 
 * E2EE
 * https://matrix.org/docs/spec/client_server/latest#id76
 */

import 'package:Tether/global/libs/matrix/index.dart';
import 'package:Tether/store/alerts/actions.dart';
import 'package:Tether/store/crypto/model.dart';
import 'package:Tether/store/index.dart';
import 'package:Tether/store/user/model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

final protocol = DotEnv().env['PROTOCOL'];

class SetDeviceKeys {
  var deviceKeys;
  SetDeviceKeys({this.deviceKeys});
}

ThunkAction<AppState> fetchDeviceKeys({
  Map<String, User> users,
}) {
  return (Store<AppState> store) async {
    try {
      final userMap = users.map((userId, user) => MapEntry(userId, const []));

      final data = await MatrixApi.fetchKeys(
        protocol: protocol,
        homeserver: store.state.authStore.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        lastSince: store.state.syncStore.lastSince,
        users: userMap,
      );

      final Map<dynamic, dynamic> deviceKeys = data['device_keys'];

      Map<String, Map<String, DeviceKey>> newDeviceKeys = {};

      deviceKeys.forEach((userId, devices) {
        print('[fetchDeviceKeys] $userId $devices');
        devices.forEach((deviceId, device) {
          final deviceKey = DeviceKey.fromJson(device);
          if (newDeviceKeys[userId] == null) {
            newDeviceKeys[userId] = {};
          }

          newDeviceKeys[userId][deviceId] = deviceKey;
        });
      });

      store.dispatch(SetDeviceKeys(
        deviceKeys: newDeviceKeys,
      ));

      print(data);
    } catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error));
    }
  };
}

ThunkAction<AppState> fetchUserDeviceKeyChanges({
  List<User> users,
}) {
  return (Store<AppState> store) async {
    try {} catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error));
    }
  };
}

ThunkAction<AppState> generateIdentityKey({
  List<User> users,
}) {
  return (Store<AppState> store) async {
    try {} catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error));
    }
  };
}

ThunkAction<AppState> uploadIdentityKey({
  List<User> users,
}) {
  return (Store<AppState> store) async {
    try {} catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error));
    }
  };
}
