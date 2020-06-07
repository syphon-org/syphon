import 'dart:convert';
import 'dart:io';

import 'package:Tether/global/libs/matrix/encryption.dart';
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
import 'package:canonical_json/canonical_json.dart';
import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

final protocol = DotEnv().env['PROTOCOL'];

class SetDeviceKeys {
  var deviceKeys;
  SetDeviceKeys({this.deviceKeys});
}

// Set currently authenticated users keys
class SetDeviceKeysOwned {
  var deviceKeysOwned;
  SetDeviceKeysOwned({this.deviceKeysOwned});
}

// alerts the user they need to import keys
// if none are owned and present on device
// set if device public keys exist remotely
class ToggleDeviceKeysExist {
  var existence;
  ToggleDeviceKeysExist({this.existence});
}

ThunkAction<AppState> setDeviceKeys(Map deviceKeys) {
  return (Store<AppState> store) async {
    store.dispatch(SetDeviceKeys(deviceKeys: deviceKeys));
  };
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
        devices.forEach((deviceId, device) {
          // print('[fetchDeviceKeys] $userId $device');
          final deviceKey = DeviceKey.fromJson(device);
          if (newDeviceKeys[userId] == null) {
            newDeviceKeys[userId] = {};
          }

          newDeviceKeys[userId][deviceId] = deviceKey;
        });
      });

      return newDeviceKeys;
    } catch (error) {
      print('[fetchDeviceKeys] error $error');
      store.dispatch(addAlert(type: 'warning', message: error));
      return const {};
    }
  };
}

ThunkAction<AppState> fetchDeviceKeysOwned() {
  return (Store<AppState> store) async {
    final user = store.state.authStore.user;
    final deviceKeys = await store.dispatch(fetchDeviceKeys(users: {
      user.userId: user,
    }));
    return deviceKeys[user.userId];
  };
}

ThunkAction<AppState> setDeviceKeysOwned(Map deviceKeysOwned) {
  return (Store<AppState> store) async {
    store.dispatch(SetDeviceKeysOwned(deviceKeysOwned: deviceKeysOwned));
  };
}

ThunkAction<AppState> toggleDeviceKeysExist(bool existence) {
  return (Store<AppState> store) async {
    store.dispatch(ToggleDeviceKeysExist(existence: existence));
  };
}

/**
 * 
 * Generating Device Keys
 * 
 * https://matrix.org/docs/spec/client_server/latest#id427
 * https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide
 * https://pub.dev/documentation/cryptography/latest/
 * https://matrix.org/docs/spec/appendices#id7
 * https://matrix.org/docs/spec/appendices#id2
 * 
 */
ThunkAction<AppState> generateDeviceKey() {
  return (Store<AppState> store) async {
    try {
      final authUser = store.state.authStore.user;
      // final Device currentDevice = await store.dispatch(generateDeviceId());

      // fingerprint keypair - ed25519
      final fingerprintKeyName =
          '${MatrixAlgorithms.ed25519}:${authUser.deviceId}';
      final fingerprintKeyPair = await ed25519.newKeyPair();

      // identity key pair - curve25519
      final identityKeyName =
          '${MatrixAlgorithms.curve25591}:${authUser.deviceId}';
      final identityKeyPair = await x25519.newKeyPair();

      // unpadded base64 encode
      final encodedFingerprintPublicKey = base64Encode(
        fingerprintKeyPair.publicKey.bytes,
      ).replaceAll("=", '');

      final encodedIdentityPublicKey = base64Encode(
        identityKeyPair.publicKey.bytes,
      ).replaceAll("=", '');

      // formatting json for the signature required by matrix
      var deviceKeys = {
        'device_keys': {
          'algorithms': [
            MatrixAlgorithms.olmv1,
            MatrixAlgorithms.megolmv1,
          ],
          'device_id': authUser.deviceId,
          'keys': {
            identityKeyName: encodedIdentityPublicKey,
            fingerprintKeyName: encodedFingerprintPublicKey,
          },
          'user_id': authUser.userId,
        }
      };

      // figerprint signature key pair generation
      final deviceKeyJsonBytes = canonicalJson.encode(deviceKeys);
      final fingerprintSignature = await ed25519.sign(
        deviceKeyJsonBytes,
        fingerprintKeyPair,
      );

      // fingerprint signature encoding for upload
      final encodedFingerprintSignature = base64Encode(
        fingerprintSignature.bytes,
      ).replaceAll("=", '');

      // figerprint signature key pair appended for upload
      deviceKeys['device_keys']['signatures'] = {
        authUser.userId: {
          fingerprintKeyName: encodedFingerprintSignature,
        }
      };

      // Cache the private device keys
      final fingerprintPrivateKey =
          await fingerprintKeyPair.privateKey.extract();
      final identityPrivateKey = await identityKeyPair.privateKey.extract();

      final Map<String, String> privateKeys = {
        fingerprintKeyName: base64Encode(fingerprintPrivateKey),
        identityKeyName: base64Encode(identityPrivateKey),
      };

      // print(
      //   '[generateDeviceKey] ${authUser.userId} ${deviceKeys['device_keys']}',
      // );

      // converting to deviceKey model
      final deviceKeysOwned = DeviceKey.fromJson(
        deviceKeys['device_keys'],
        privateKeys: privateKeys,
      );

      // print(
      //   '[generateDeviceKey] deviceKeysOwned Object $deviceKeysOwned',
      // );

      // cache current device, device key for authed user
      store.dispatch(SetDeviceKeysOwned(
        deviceKeysOwned: {
          authUser.deviceId: deviceKeysOwned,
        },
      ));
    } catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error));
    }
  };
}

ThunkAction<AppState> uploadDeviceKey({DeviceKey deviceKey}) {
  return (Store<AppState> store) async {
    try {
      final deviceKeyMap = {
        'device_keys': deviceKey.toMap(),
      };
      print(
        '[uploadDeviceKey] deviceKey ${deviceKeyMap}',
      );

      // upload the public device keys
      // final data = await MatrixApi.uploadKeys(
      //   protocol: protocol,
      //   homeserver: store.state.authStore.homeserver,
      //   accessToken: store.state.authStore.user.accessToken,
      //   data: deviceKeyMap,
      // );

      // if (data['errcode'] != null) {
      //   throw data['error'];
      // }

      // print(data);
    } catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error));
      print(error);
    }
  };
}

ThunkAction<AppState> exportDeviceKeysOwned() {
  return (Store<AppState> store) async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      final currentTime = DateTime.now();
      final formattedTime =
          DateFormat('MMM_dd_yyyy_hh_mm_aa').format(currentTime).toLowerCase();
      final fileName =
          '${directory.path}/tether_key_export_$formattedTime.json';

      var file = File(fileName);

      final user = store.state.authStore.user;
      final deviceKey = store.state.cryptoStore.deviceKeysOwned[user.deviceId];

      print('[exportDeviceKeysOwned] $deviceKey');

      file = await file.writeAsString(json.encode(deviceKey.toMap()));

      // print(data);
    } catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error));
      print(error);
    }
  };
}

ThunkAction<AppState> importDeviceKeysOwned() {
  return (Store<AppState> store) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> files = directory.listSync();

      files.forEach((file) {
        print(file);
      });
      File file = await FilePicker.getFile(allowedExtensions: ['.json']);
    } catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error));
      print(error);
    }
  };
}

/**
 * Generate Message Keys (One Time Keys)
 * 
 * 
 * AKA Session keys
 * 
 */
ThunkAction<AppState> generateMessageKeys() {
  return (Store<AppState> store) async {
    try {} catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error));
    }
  };
}

ThunkAction<AppState> uploadMessageKeys({
  List<User> users,
}) {
  return (Store<AppState> store) async {
    try {} catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error));
    }
  };
}
