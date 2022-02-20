import 'dart:async';
import 'dart:convert';

import 'package:canonical_json/canonical_json.dart';
import 'package:crypto/crypto.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/crypto/keys/models.dart';
import 'package:syphon/store/crypto/sessions/actions.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/user/model.dart';

class SetDeviceKeys {
  var deviceKeys;
  SetDeviceKeys({this.deviceKeys});
}

// Set currently authenticated users keys
class SetDeviceKeysOwned {
  Map<String, DeviceKey>? deviceKeysOwned;
  SetDeviceKeysOwned({this.deviceKeysOwned});
}

// alerts the user they need to import keys
// if none are owned and present on device
// set if device public keys exist remotely
class ToggleDeviceKeysExist {
  var existence;
  ToggleDeviceKeysExist({this.existence});
}

class SetOneTimeKeysCounts {
  Map<String, int>? oneTimeKeysCounts;
  SetOneTimeKeysCounts({this.oneTimeKeysCounts});
}

class SetOneTimeKeysStable {
  bool stable;
  SetOneTimeKeysStable({required this.stable});
}

class SetOneTimeKeysClaimed {
  var oneTimeKeys;
  SetOneTimeKeysClaimed({this.oneTimeKeys});
}

/// Helper Actions
ThunkAction<AppState> setDeviceKeysOwned(Map deviceKeys) {
  return (Store<AppState> store) async {
    final Map<String, DeviceKey> currentKeys = Map.from(
      store.state.cryptoStore.deviceKeysOwned,
    );

    deviceKeys.forEach((key, value) {
      currentKeys.putIfAbsent(key, () => deviceKeys[key]);
    });

    store.dispatch(SetDeviceKeysOwned(deviceKeysOwned: currentKeys));
  };
}

ThunkAction<AppState> toggleDeviceKeysExist(bool existence) {
  return (Store<AppState> store) async {
    store.dispatch(ToggleDeviceKeysExist(existence: existence));
  };
}

ThunkAction<AppState> setDeviceKeys(Map? deviceKeys) {
  return (Store<AppState> store) {
    store.dispatch(SetDeviceKeys(deviceKeys: deviceKeys));
  };
}

ThunkAction<AppState> setOneTimeKeysClaimed(
  Map<String, OneTimeKey> oneTimeKeys,
) {
  return (Store<AppState> store) {
    store.dispatch(SetOneTimeKeysClaimed(oneTimeKeys: oneTimeKeys));
  };
}

ThunkAction<AppState> generateIdentityKeys() {
  return (Store<AppState> store) async {
    try {
      final authUser = store.state.authStore.user;
      final olmAccount = store.state.cryptoStore.olmAccount!;

      final identityKeys = await json.decode(olmAccount.identity_keys());

      final fingerprintId = Keys.fingerprintId(deviceId: authUser.deviceId);
      final identityKeyId = Keys.identityKeyId(deviceId: authUser.deviceId);

      // formatting json for the signature required by matrix
      final deviceIdentityKeys = {
        'algorithms': [
          Algorithms.olmv1,
          Algorithms.megolmv1,
        ],
        'device_id': authUser.deviceId,
        'keys': {
          fingerprintId: identityKeys[Algorithms.ed25519],
          identityKeyId: identityKeys[Algorithms.curve25591],
        },
        'user_id': authUser.userId,
      };

      // fingerprint signature key pair generation for upload
      final deviceKeysEncoded = canonicalJson.encode(deviceIdentityKeys);
      final deviceKeysSerialized = utf8.decode(deviceKeysEncoded);
      final deviceKeysSigned = olmAccount.sign(deviceKeysSerialized);

      final deviceKeysPayload = {'device_keys': deviceIdentityKeys};

      deviceKeysPayload['device_keys']?['signatures'] = {
        authUser.userId: {
          fingerprintId: deviceKeysSigned,
        }
      };

      // cache current device key for authed user
      final deviceKeysOwned = DeviceKey.fromMatrix(
        deviceKeysPayload['device_keys'],
      );

      await store.dispatch(SetDeviceKeysOwned(
        deviceKeysOwned: {authUser.deviceId!: deviceKeysOwned},
      ));

      // return the generated keys
      return deviceKeysOwned;
    } catch (error) {
      printError('[generateIdentityKeys] $error');
      return null;
    }
  };
}

ThunkAction<AppState> uploadIdentityKeys({required DeviceKey deviceKey}) {
  return (Store<AppState> store) async {
    try {
      final deviceKeyMap = {
        'device_keys': deviceKey.toMatrix(),
      };

      // upload the public device keys
      final data = await MatrixApi.uploadKeys(
        protocol: store.state.authStore.protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        data: deviceKeyMap,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        origin: 'uploadIdentityKeys',
      ));
    }
  };
}

/// Generate One Time Keys
///
/// Returns the keys as a map
ThunkAction<AppState> generateOneTimeKeys({DeviceKey? deviceKey}) {
  return (Store<AppState> store) async {
    try {
      final olmAccount = store.state.cryptoStore.olmAccount!;
      olmAccount.generate_one_time_keys(5); // synchronous
      return json.decode(olmAccount.one_time_keys());
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        origin: 'generateOneTimeKeys',
      ));
    }
  };
}

ThunkAction<AppState> signOneTimeKeys(Map? oneTimeKeys) {
  return (Store<AppState> store) async {
    final authUser = store.state.authStore.user;
    final olmAccount = store.state.cryptoStore.olmAccount!;

    final oneTimeKeysSignedAll = {};

    // Signing Keys
    oneTimeKeys!.forEach((key, value) {
      final oneTimeKey = {'key': value};

      // sign one time keys
      final oneTimeKeyEncoded = canonicalJson.encode(oneTimeKey);
      final oneTimeKeySerialized = utf8.decode(oneTimeKeyEncoded);
      final oneTimeKeySigned = olmAccount.sign(oneTimeKeySerialized);

      // add one time key in new keys map only
      final keyId = key.split(':')[0];
      final oneTimeKeyId = Keys.oneTimeKeyId(keyId: keyId);
      oneTimeKeysSignedAll[oneTimeKeyId] = {'key': value};

      final fingerprintKeyId = Keys.fingerprintId(deviceId: authUser.deviceId);

      // append signature for new signed key
      oneTimeKeysSignedAll[oneTimeKeyId]['signatures'] = {
        authUser.userId: {
          fingerprintKeyId: oneTimeKeySigned,
        }
      };
    });

    return oneTimeKeysSignedAll;
  };
}

///
/// Update One Time Key Counts
///
/// Always run this function for every fetchSync or /sync call made
/// *** Synapse *** will return the number of keyCounts available, and for every
/// payload, this function will determine if updates are needed
///
/// *** Dendrite *** does not return current key counts
/// through /sync _unless_ they change
///
ThunkAction<AppState> updateOneTimeKeyCounts(Map<String, int> oneTimeKeyCounts) {
  return (Store<AppState> store) async {
    final currentKeyCounts = store.state.cryptoStore.oneTimeKeysCounts;

    printInfo('[updateOneTimeKeyCounts] $oneTimeKeyCounts, current $currentKeyCounts');

    // Confirm user has access token
    final accessToken = store.state.authStore.user.accessToken;
    if (accessToken == null) {
      return;
    }

    // Confirm user has generated an olm account
    final olmAccount = store.state.cryptoStore.olmAccount;
    if (olmAccount == null) {
      return;
    }

    // dont attempt to update before deviceKeys are populated
    final noDeviceKeysOwned = store.state.cryptoStore.deviceKeysOwned.isEmpty;
    if (noDeviceKeysOwned) {
      return;
    }

    final syncedKeyCount = oneTimeKeyCounts[Algorithms.signedcurve25519] ?? 0;
    final currentKeyCount = currentKeyCounts[Algorithms.signedcurve25519] ?? 0;

    // if the key count hasn't changed, don't update it
    if (currentKeyCounts.isNotEmpty && currentKeyCount == syncedKeyCount) {
      return;
    }

    // if the new OTK counts are empty, but we have some, ignore the update
    if (oneTimeKeyCounts.isEmpty && currentKeyCounts.isNotEmpty) {
      return;
    }

    printInfo(
      '[updateOneTimeKeyCounts] Updating $oneTimeKeyCounts, current $currentKeyCounts',
    );

    store.dispatch(SetOneTimeKeysCounts(
      oneTimeKeysCounts: oneTimeKeyCounts,
    ));

    // register new key counts
    final int maxKeyCount = olmAccount.max_number_of_one_time_keys();

    // the last check is because im scared
    if ((syncedKeyCount < maxKeyCount / 3) && syncedKeyCount < 100) {
      store.dispatch(updateOneTimeKeys());
    } else {
      store.dispatch(SetOneTimeKeysStable(stable: true));
    }
  };
}

ThunkAction<AppState> updateOneTimeKeys({type = Algorithms.signedcurve25519}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetOneTimeKeysStable(stable: false));
      final olmAccount = store.state.cryptoStore.olmAccount!;

      var newOneTimeKeys = await store.dispatch(
        generateOneTimeKeys(),
      );

      if (type == Algorithms.signedcurve25519) {
        newOneTimeKeys = await store.dispatch(
          signOneTimeKeys(newOneTimeKeys[Algorithms.curve25591]),
        );
      }

      final payload = {
        'one_time_keys': newOneTimeKeys,
      };

      final data = await MatrixApi.uploadKeys(
        protocol: store.state.authStore.protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        data: payload,
      );

      // Recoverable error from matrix
      if (data['errcode'] != null) {
        throw data['error'];
      }

      printInfo('[updateOneTimeKeys] successfully uploaded oneTimeKeys');

      // save account state after successful upload
      olmAccount.mark_keys_as_published();
      await store.dispatch(saveOlmAccount());

      // register new key counts
      store.dispatch(updateOneTimeKeyCounts(
        Map<String, int>.from(data['one_time_key_counts']),
      ));

      printInfo('[updateOneTimeKeys] successfully updated oneTimeKeys');
    } catch (error) {
      store.dispatch(addAlert(
          error: error,
          message: 'Failed to updated one time keys, please let us know at https://syphon.org',
          origin: 'updateOneTimeKeys'));
    }
  };
}

///
/// Claims keys for devices and creates key sharing session
///
ThunkAction<AppState> claimOneTimeKeys({
  required Room room,
  required List<DeviceKey> deviceKeys,
}) {
  return (Store<AppState> store) async {
    try {
      // Create a map of all the oneTimeKeys to claim for unestablished sessions
      final claimKeysPayload = deviceKeys.fold(
        Map.from({}),
        (Map claims, deviceKey) {
          // init claims object for user ID
          if (claims[deviceKey.userId] == null) {
            claims[deviceKey.userId] = {};
          }

          // add device ID to userID claims
          claims[deviceKey.userId][deviceKey.deviceId] = Algorithms.signedcurve25519;

          return claims;
        },
      );

      // format oneTimeKey map from keys claimed in response
      final Map<String, OneTimeKey> oneTimekeys = {};

      // stop if one time keys for known devices already exist
      if (claimKeysPayload.isEmpty) {
        printInfo('[claimOneTimeKeys] all key sharing sessions per device are ready');
        return true;
      }

      // claim one time keys from matrix server
      final Map claimKeysResponse = await MatrixApi.claimKeys(
        protocol: store.state.authStore.protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        oneTimeKeys: claimKeysPayload,
      );

      if (claimKeysResponse['errcode'] != null || claimKeysResponse['failures'].isNotEmpty) {
        throw claimKeysResponse['error'];
      }

      final oneTimeKeysClaimed = claimKeysResponse['one_time_keys'];

      // Must be without types for forEach
      oneTimeKeysClaimed.forEach((userId, deviceOneTimeKeys) {
        // Must be without types for forEach
        deviceOneTimeKeys.forEach((deviceId, oneTimeKey) {
          // Parsing the oneTimeKey responses into the oneTimeKey model
          final String oneTimeKeyIdentity = oneTimeKey.keys.elementAt(0);
          final String? oneTimeKeyHash = oneTimeKey[oneTimeKeyIdentity]['key'];
          final oneTimeKeySignature = Map<String, String>.from(
            oneTimeKey[oneTimeKeyIdentity]['signatures'][userId],
          );

          oneTimekeys[deviceId] = OneTimeKey(
            userId: userId,
            deviceId: deviceId,
            keys: {
              oneTimeKeyIdentity: oneTimeKeyHash,
            },
            signatures: {
              oneTimeKeyIdentity: oneTimeKeySignature,
            },
          );
        });
      });

      await Future.forEach(oneTimekeys.keys, (deviceId) async {
        final oneTimeKey = oneTimekeys[deviceId];

        if (oneTimeKey == null) return;

        final userId = oneTimeKey.userId;
        final deviceKey = store.state.cryptoStore.deviceKeys[userId!]![deviceId]!;
        final identityKeyId = Keys.identityKeyId(deviceId: deviceKey.deviceId);
        final identityKey = deviceKey.keys![identityKeyId];

        await store.dispatch(createKeySessionOutbound(
          identityKey: identityKey,
          oneTimeKey: oneTimeKey.keys.values.elementAt(0),
        ));
      });

      return true;
    } catch (error) {
      store.dispatch(addAlert(
        origin: 'claimOneTimeKeys',
        message: error.toString(),
      ));
      return false;
    }
  };
}

///
/// Fetch Device Keys
///
/// fetches the keys uploaded to the matrix homeserver
/// by other users
ThunkAction<AppState> fetchDeviceKeys({
  List<String?> userIds = const <String>[],
}) {
  return (Store<AppState> store) async {
    try {
      final Map<String, dynamic> userIdMap = Map.fromIterable(
        userIds,
        key: (userId) => userId,
        value: (userId) => const [],
      );

      final data = await MatrixApi.fetchKeys(
        protocol: store.state.authStore.protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        lastSince: store.state.syncStore.lastSince,
        users: userIdMap,
      );

      final Map<dynamic, dynamic> deviceKeys = data['device_keys'];
      final Map<String, Map<String, DeviceKey>> newDeviceKeys = {};

      deviceKeys.forEach((userId, devices) {
        devices.forEach((deviceId, device) {
          final deviceKey = DeviceKey.fromMatrix(device);

          if (newDeviceKeys[userId] == null) {
            newDeviceKeys[userId] = {};
          }

          newDeviceKeys[userId]![deviceId] = deviceKey;
        });
      });

      return newDeviceKeys;
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        origin: 'fetchDeviceKeys',
      ));
      return const {};
    }
  };
}

ThunkAction<AppState> fetchDeviceKeysOwned(User user) {
  return (Store<AppState> store) async {
    final deviceKeys = await store.dispatch(
      fetchDeviceKeys(userIds: [user.userId]),
    );
    return deviceKeys[user.userId];
  };
}

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
