/**
 * 
 * Magnolia
 * 
 * Eventually, a dart native implimentation of double ratchet
 * 
 * these are just actions created while I was trying to
 * implement double ratchet alongside the matrix protocols
 * needs, they no longer work within syphon and are just 
 * there for documentation
 */

/*
import 'dart:convert';

import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/crypto/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/model.dart';
import 'package:canonical_json/canonical_json.dart';
import 'package:cryptography/cryptography.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

ThunkAction<AppState> initKeyEncryption(User user) {
  return (Store<AppState> store) async {
    // fetch device keys and pull out key based on device id
    final ownedDeviceKeys = await store.dispatch(
      fetchDeviceKeysOwned(),
    );

    // check if key exists for this device
    if (!ownedDeviceKeys.containsKey(user.deviceId)) {
      // generate a key if none exist locally and remotely
      if (store.state.cryptoStore.deviceKeysOwned.isEmpty) {
        await store.dispatch(initOlmEncryption(user));
      }

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

ThunkAction<AppState> exportDeviceKeysOwned() {
  return (Store<AppState> store) async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      final currentTime = DateTime.now();

      final formattedTime =
          DateFormat('MMM_dd_yyyy_hh_mm_aa').format(currentTime).toLowerCase();

      final fileName =
          '${directory.path}/app_key_export_$formattedTime.json';

      var file = File(fileName);

      final user = store.state.authStore.user;
      final deviceKey = store.state.cryptoStore.deviceKeysOwned[user.deviceId];
  
      file = await file.writeAsString(
        json.encode(deviceKey.toMap(),
      );
 
    } catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error)); 
    }
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
ThunkAction<AppState> generateDeviceKeyManual() {
  return (Store<AppState> store) async {
    try {
      final authUser = store.state.authStore.user;
      // final Device currentDevice = await store.dispatch(generateDeviceId());

      // fingerprint keypair - ed25519
      final fingerprintKeyName =
          '${Algorithms.ed25519}:${authUser.deviceId}';
      final fingerprintKeyPair = await ed25519.newKeyPair();

      // identity key pair - curve25519
      final identityKeyName =
          '${Algorithms.curve25591}:${authUser.deviceId}';
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
            Algorithms.olmv1,
            Algorithms.megolmv1,
          ],
          'device_id': authUser.deviceId,
          'keys': {
            identityKeyName: encodedIdentityPublicKey,
            fingerprintKeyName: encodedFingerprintPublicKey,
          },
          'user_id': authUser.userId,
        }
      };

      // figerprint signature key pair generation for upload
      final deviceKeyJsonBytes = canonicalJson.encode(deviceKeys);
      final fingerprintSignature = await ed25519.sign(
        deviceKeyJsonBytes,
        fingerprintKeyPair,
      );
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

      // converting to deviceKey model
      final deviceKeysOwned = DeviceKey.fromJson(
        deviceKeys['device_keys'],
        privateKeys: privateKeys,
      );

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

ThunkAction<AppState> setDeviceKeysOwned(Map deviceKeys) {
  return (Store<AppState> store) async {
    var currentKeys = Map<String, DeviceKey>.from(
      store.state.cryptoStore.deviceKeysOwned,
    );

    deviceKeys.forEach((key, value) {
      currentKeys.putIfAbsent(key, () => deviceKeys[key]); 
    });

    store.dispatch(SetDeviceKeysOwned(deviceKeysOwned: currentKeys));
  };
}
*/
