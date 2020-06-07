import 'dart:convert';
import 'dart:io';

import 'package:Tether/global/libs/matrix/encryption.dart';
import 'package:Tether/global/libs/matrix/index.dart';
import 'package:Tether/store/alerts/actions.dart';
import 'package:Tether/store/crypto/model.dart';
import 'package:Tether/store/index.dart';
import 'package:Tether/store/user/model.dart';
import 'package:canonical_json/canonical_json.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:olm/olm.dart' as olmClient;

/**
 * 
 * E2EE
 * https://matrix.org/docs/spec/client_server/latest#id76
 */

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

// Set currently authenticated users keys
class SetOlmAccount {
  var olmAccount;
  SetOlmAccount({this.olmAccount});
}

class SetOlmAccountBackup {
  var olmAccountKey;
  SetOlmAccountBackup({this.olmAccountKey});
}

class SetOneTimeKeysCounts {
  var oneTimeKeysCounts;
  SetOneTimeKeysCounts({this.oneTimeKeysCounts});
}

class ResetDeviceKeys {}

/**
 * Helper Actions
 */
ThunkAction<AppState> setDeviceKeysOwned(Map deviceKeys) {
  return (Store<AppState> store) async {
    var currentKeys = Map<String, DeviceKey>.from(
      store.state.cryptoStore.deviceKeysOwned,
    );

    deviceKeys.forEach((key, value) {
      currentKeys.putIfAbsent(key, () => deviceKeys[key]);
      // print('[setDeviceKeysOwned] ${currentKeys[key]}'); // TESTING ONLY
    });

    store.dispatch(SetDeviceKeysOwned(deviceKeysOwned: currentKeys));
  };
}

ThunkAction<AppState> toggleDeviceKeysExist(bool existence) {
  return (Store<AppState> store) async {
    store.dispatch(ToggleDeviceKeysExist(existence: existence));
  };
}

ThunkAction<AppState> setDeviceKeys(Map deviceKeys) {
  return (Store<AppState> store) async {
    store.dispatch(SetDeviceKeys(deviceKeys: deviceKeys));
  };
}

ThunkAction<AppState> deleteDeviceKeys() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(ResetDeviceKeys());
    } catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error));
      print(error);
    }
  };
}

ThunkAction<AppState> backupOlmAccount() {
  return (Store<AppState> store) async {
    try {
      final deviceId = store.state.authStore.user.deviceId;
      final olmAccount = store.state.cryptoStore.olmAccount;
      final olmAccountKey = olmAccount.pickle(deviceId);
      store.dispatch(SetOlmAccountBackup(olmAccountKey: olmAccountKey));
    } catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error));
      print(error);
    }
  };
}

/**
 * Init Key Encryption
 */
ThunkAction<AppState> initKeyEncryption(User user) {
  return (Store<AppState> store) async {
    // fetch device keys and pull out key based on device id
    final ownedDeviceKeys = (await store.dispatch(
          fetchDeviceKeysOwned(user),
        )) ??
        {};

    await store.dispatch(initOlmEncryption(user));

    // check if key exists for this device
    if (!ownedDeviceKeys.containsKey(user.deviceId)) {
      // generate a key if none exist locally and remotely
      await store.dispatch(generateIdentityKeys());

      final deviceId = store.state.authStore.user.deviceId;
      final deviceKey = store.state.cryptoStore.deviceKeysOwned[deviceId];

      // upload the key intended for this device
      await store.dispatch(uploadIdentityKeys(deviceKey: deviceKey));
    } else {
      // if a key exists remotely, mark that it does
      // the user will be prompted to import in "home"
      // if they have no local keys
      store.dispatch(toggleDeviceKeysExist(true));
    }

    // append all keys uploaded remotely
    store.dispatch(setDeviceKeysOwned(ownedDeviceKeys));
  };
}

/**
 * 
 * Initing Olm Account
 * 
 * https://gitlab.matrix.org/matrix-org/olm/-/blob/master/python/olm/account.py
 * 
 * Uses deviceId to encrypt and serialize the account (pickle)
 * needed to know about the python library to know what that was
 */
ThunkAction<AppState> initOlmEncryption(User user) {
  return (Store<AppState> store) async {
    try {
      await olmClient.init();
      final olmAccount = olmClient.Account();

      final deviceId = store.state.authStore.user.deviceId;
      final olmAccountKey = store.state.cryptoStore.olmAccountKey;

      if (olmAccountKey == null) {
        olmAccount.create();
        final olmAccountKey = olmAccount.pickle(deviceId);

        store.dispatch(SetOlmAccountBackup(olmAccountKey: olmAccountKey));

        store.dispatch(SetOlmAccount(olmAccount: olmAccount));

        print(
          '[initOlmEncryption] new identity keys ${olmAccount.identity_keys()}',
        );
      } else {
        olmAccount.unpickle(deviceId, olmAccountKey);

        store.dispatch(SetOlmAccount(olmAccount: olmAccount));

        print(
          '[initOlmEncryption] old olm ${olmAccount.identity_keys()}',
        );
      }
    } catch (error) {
      print('[initOlmEncryption] $error');
    }
  };
}

ThunkAction<AppState> generateIdentityKeys() {
  return (Store<AppState> store) async {
    try {
      final authUser = store.state.authStore.user;
      final olmAccount = store.state.cryptoStore.olmAccount;

      final identityKeysString = olmAccount.identity_keys();
      final identityKeys = await json.decode(identityKeysString);
      // fingerprint keypair - ed25519
      final fingerprintKeyName = '${Algorithms.ed25519}:${authUser.deviceId}';

      // identity key pair - curve25519
      final identityKeyName = '${Algorithms.curve25591}:${authUser.deviceId}';

      // formatting json for the signature required by matrix
      var deviceIdentityKeys = {
        'device_keys': {
          'algorithms': [
            Algorithms.olmv1,
            Algorithms.megolmv1,
          ],
          'device_id': authUser.deviceId,
          'keys': {
            identityKeyName: identityKeys[Algorithms.curve25591],
            fingerprintKeyName: identityKeys[Algorithms.ed25519],
          },
          'user_id': authUser.userId,
        }
      };

      // figerprint signature key pair generation for upload
      final identityKeyJsonBytes = canonicalJson.encode(deviceIdentityKeys);
      final identityKeyJsonString = utf8.decode(identityKeyJsonBytes);
      print('[generateIdentityKeys] $identityKeyJsonString');
      final signedIdentityKey = olmAccount.sign(identityKeyJsonString);
      print('[generateIdentityKeys] $signedIdentityKey');

      deviceIdentityKeys['device_keys']['signatures'] = {
        authUser.userId: {
          fingerprintKeyName: signedIdentityKey,
        }
      };

      // cache current device key for authed user
      final deviceKeysOwned = DeviceKey.fromJson(
        deviceIdentityKeys['device_keys'],
      );

      store.dispatch(SetDeviceKeysOwned(
        deviceKeysOwned: {
          authUser.deviceId: deviceKeysOwned,
        },
      ));

      print('[generateIdentityKeys] $deviceIdentityKeys');
      // return the generated keys
      return deviceIdentityKeys;
    } catch (error) {
      print('[generateIdentityKeys] $error');
    }
  };
}

ThunkAction<AppState> uploadIdentityKeys({DeviceKey deviceKey}) {
  return (Store<AppState> store) async {
    try {
      final deviceKeyMap = {
        'device_keys': deviceKey.toMap(),
      };

      print(
        '[uploadDeviceKey] result ${deviceKeyMap}',
      );

      // upload the public device keys
      final data = await MatrixApi.uploadKeys(
        protocol: protocol,
        homeserver: store.state.authStore.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        data: deviceKeyMap,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      store.dispatch(addAlert(
        type: 'confirmation',
        message: 'Successfully uploaded new device key',
      ));
    } catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error));
      print(error);
    }
  };
}

/**
 * Generate One Time Keys
 * 
 * Returns the keys as a map
 */
ThunkAction<AppState> generateOneTimeKeys({DeviceKey deviceKey}) {
  return (Store<AppState> store) async {
    try {
      final olmAccount = store.state.cryptoStore.olmAccount;
      olmAccount.generate_one_time_keys(5); // synchronous
      return json.decode(olmAccount.one_time_keys());
    } catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error));
      print(error);
    }
  };
}

ThunkAction<AppState> signOneTimeKeys(Map oneTimeKeys) {
  return (Store<AppState> store) async {
    final olmAccount = store.state.cryptoStore.olmAccount;
    final authUser = store.state.authStore.user;

    final signedKeysMap = {};

    // Signing Keys
    oneTimeKeys.forEach((key, value) {
      var oneTimeKey = {'$key': '$value'};
      final identityKeyJsonBytes = canonicalJson.encode(oneTimeKey);
      final identityKeyJsonString = utf8.decode(identityKeyJsonBytes);
      final signedIdentityKey = olmAccount.sign(identityKeyJsonString);

      // Update key id in new keys map only
      final keyId = key.split(':')[0];
      final newKey = '${Algorithms.signedcurve25519}:$keyId';
      signedKeysMap[newKey] = {'key': value};

      // appending signature for new signed key
      signedKeysMap[newKey]['signatures'] = {
        authUser.userId: {
          '${Algorithms.ed25519}:${authUser.deviceId}': signedIdentityKey,
        }
      };
    });

    return signedKeysMap;
  };
}

ThunkAction<AppState> updateOneTimeKeyCounts(Map oneTimeKeysCounts) {
  return (Store<AppState> store) async {
    store.dispatch(
      SetOneTimeKeysCounts(oneTimeKeysCounts: oneTimeKeysCounts),
    );

    final olmAccount = store.state.cryptoStore.olmAccount;
    if (olmAccount == null) {
      return;
    }

    // TODO: not sure if we ever need unsigned keys
    // final int curveCount = oneTimeKeysCounts[Algorithms.curve25591] ?? 0;

    final int maxKeyCount = olmAccount.max_number_of_one_time_keys();
    final int signedCurveCount =
        oneTimeKeysCounts[Algorithms.signedcurve25519] ?? 0;

    if ((signedCurveCount < maxKeyCount / 3)) {
      store.dispatch(updateOneTimeKeys());
    }
  };
}

ThunkAction<AppState> updateOneTimeKeys({type = Algorithms.signedcurve25519}) {
  return (Store<AppState> store) async {
    try {
      final olmAccount = store.state.cryptoStore.olmAccount;

      var newOneTimeKeys = await store.dispatch(
        generateOneTimeKeys(),
      );

      if (type == Algorithms.signedcurve25519) {
        newOneTimeKeys = await store.dispatch(
          signOneTimeKeys(newOneTimeKeys[Algorithms.curve25591]),
        );
      }

      print('[updateOneTimeKeys] $newOneTimeKeys');

      final payload = {
        'one_time_keys': newOneTimeKeys,
      };

      final data = await MatrixApi.uploadKeys(
        protocol: protocol,
        homeserver: store.state.authStore.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        data: payload,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      final oneTimeKeysCounts = store.state.cryptoStore.oneTimeKeysCounts;
      if (data['one_time_key_counts'][type] != oneTimeKeysCounts) {
        store.dispatch(updateOneTimeKeyCounts(data['one_time_key_counts']));
      }

      print('[updateOneTimeKeys] success $data');

      olmAccount.mark_keys_as_published();
      store.dispatch(backupOlmAccount());
    } catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error));
    }
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
          print('[fetchDeviceKeys] $userId $device'); // TESTING ONLY
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

ThunkAction<AppState> fetchDeviceKeysOwned(User user) {
  return (Store<AppState> store) async {
    final deviceKeys = await store.dispatch(
      fetchDeviceKeys(users: {
        user.userId: user,
      }),
    );
    return deviceKeys[user.userId];
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

      var exportData = {
        'account_key': store.state.cryptoStore.olmAccountKey,
        'device_keys': deviceKey.toMap(),
      };

      file = await file.writeAsString(json.encode(exportData));

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
      final authUser = store.state.authStore.user;
      File file = await FilePicker.getFile(
        type: FileType.custom,
        allowedExtensions: ['.json'],
      );

      final importData = await json.decode(await file.readAsString());

      store.dispatch(
        SetOlmAccountBackup(
          olmAccountKey: importData['account_key'],
        ),
      );

      store.dispatch(
        SetDeviceKeysOwned(
          deviceKeysOwned: {
            authUser.deviceId: DeviceKey.fromJson(
              importData['device_keys'],
            ),
          },
        ),
      );
    } catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error));
      print(error);
    }
  };
}
