import 'dart:convert';
import 'dart:io';

import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/crypto/events/actions.dart';
import 'package:syphon/store/crypto/keys/model.dart';
import 'package:syphon/store/crypto/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/events/model.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/user/model.dart';
import 'package:canonical_json/canonical_json.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:olm/olm.dart' as olm;

/**
 * 
 * E2EE
 * https://matrix.org/docs/spec/client_server/latest#id76
 * 
 * Outbound Message Session === Outbound Group Session (Algorithm.megolmv2)
 * Outbound Key Session === Outbound Session (Algorithm.olmv1)
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

class SetOneTimeKeysClaimed {
  var oneTimeKeys;
  SetOneTimeKeysClaimed({this.oneTimeKeys});
}

class AddOutboundKeySession {
  String identityKey;
  String session;
  AddOutboundKeySession({this.identityKey, this.session});
}

class AddInboundKeySession {
  String identityKey;
  String session;
  AddInboundKeySession({this.identityKey, this.session});
}

class AddOutboundMessageSession {
  String roomId;
  String session;
  AddOutboundMessageSession({this.roomId, this.session});
}

class DEBUGSetOutboundMessageSessionMap {
  String nothing;
  DEBUGSetOutboundMessageSessionMap({this.nothing});
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

ThunkAction<AppState> setOneTimeKeysClaimed(Map oneTimeKeys) {
  return (Store<AppState> store) {
    store.dispatch(SetOneTimeKeysClaimed(oneTimeKeys: oneTimeKeys));
  };
}

ThunkAction<AppState> deleteDeviceKeys() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(ResetDeviceKeys());
    } catch (error) {
      store.dispatch(
        addAlert(type: 'warning', message: error, origin: 'deleteDeviceKeys'),
      );
    }
  };
}

/**
 * Sync Device
 * 
 * Saves and converts events from /sync in regards to 
 * key sharing and other encryption events
 */
ThunkAction<AppState> syncDevice(Map dataToDevice) {
  return (Store<AppState> store) async {
    try {
      print('[syncDevice] NEW $dataToDevice');

      final eventsToDevice = dataToDevice['events'];

      final eventToDeviceActions = eventsToDevice.map((event) async {
        // TODO: convert to event first or after?

        switch (event.type) {
          case EventTypes.encrypted:
            return decryptKeyContent(
              content: event['content'],
            );
          default:
            return event;
        }
      });

      final eventsToDeviceFilters = await Future.wait(eventToDeviceActions);

      eventsToDeviceFilters.forEach((element) {
        print('[syncDevice] eventsToDeviceFilters.forEach $element');
      });
    } catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error));
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
      await olm.init();
      final olmAccount = olm.Account();

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

/**
 * Save Olm Account
 * 
 * serialize and save the olm account being used
 * for identity and encryption
 */
ThunkAction<AppState> saveOlmAccount() {
  return (Store<AppState> store) async {
    try {
      final deviceId = store.state.authStore.user.deviceId;
      final olmAccount = store.state.cryptoStore.olmAccount;
      final olmAccountKey = olmAccount.pickle(deviceId);
      store.dispatch(SetOlmAccountBackup(olmAccountKey: olmAccountKey));
    } catch (error) {
      store.dispatch(
        addAlert(type: 'warning', message: error, origin: 'saveOlmAccount'),
      );
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
      store.dispatch(addAlert(
        type: 'warning',
        message: error,
        origin: 'uploadIdentityKeys',
      ));
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
      store.dispatch(addAlert(
        type: 'warning',
        message: error,
        origin: 'generateOneTimeKeys',
      ));
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

// TODO: not sure if we ever need unsigned keys
// final int curveCount = oneTimeKeysCounts[Algorithms.curve25591] ?? 0;
ThunkAction<AppState> updateOneTimeKeyCounts(Map oneTimeKeysCounts) {
  return (Store<AppState> store) async {
    print('[updateOneTimeKeyCounts] updated count $oneTimeKeysCounts');

    store.dispatch(
      SetOneTimeKeysCounts(oneTimeKeysCounts: oneTimeKeysCounts),
    );

    final olmAccount = store.state.cryptoStore.olmAccount;
    if (olmAccount == null) {
      return;
    }

    final int maxKeyCount = olmAccount.max_number_of_one_time_keys();
    final int signedCurveCount =
        oneTimeKeysCounts[Algorithms.signedcurve25519] ?? 0;

    // the last check is because im scared
    if ((signedCurveCount < maxKeyCount / 3) && signedCurveCount < 100) {
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

      // save account state after successful upload
      olmAccount.mark_keys_as_published();
      await store.dispatch(saveOlmAccount());

      print('[updateOneTimeKeys] success $newOneTimeKeys $data');

      // register new key counts
      store.dispatch(updateOneTimeKeyCounts(data['one_time_key_counts']));
    } catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error));
    }
  };
}

/**
 * Claims keys for devices and creates key sharing session
 * 
 *  */
ThunkAction<AppState> claimOneTimeKeys({
  Room room,
}) {
  return (Store<AppState> store) async {
    try {
      if (!room.direct) {
        throw "Encryption currently only works for direct messaging";
      }

      final roomUsers = room.users.values;
      final deviceKeys = store.state.cryptoStore.deviceKeys;
      final outboundKeySessions = store.state.cryptoStore.outboundKeySessions;
      final currentUser = store.state.authStore.user;

      final List<DeviceKey> roomDeviceKeys = List.from(roomUsers
          .map((user) => deviceKeys[user.userId].values)
          .expand((x) => x));

      // Create a map of all the oneTimeKeys to claim
      final claimKeysPayload =
          roomDeviceKeys.fold(Map.from({}), (claims, deviceKey) {
        // don't claim your own device one time keys
        if (deviceKey.deviceId == currentUser.deviceId) return claims;
        // don't claim one time keys for already claimed devices
        if (outboundKeySessions.containsKey(deviceKey.deviceId)) return claims;

        if (claims[deviceKey.userId] == null) {
          claims[deviceKey.userId] = {};
        }

        claims[deviceKey.userId][deviceKey.deviceId] =
            Algorithms.signedcurve25519;

        return claims;
      });

      // stop if one time keys for known devices already exist
      if (claimKeysPayload.isEmpty) {
        print(
          '[claimOneTimeKeys] all key sharing sessions per device are ready',
        );
        return true;
      }

      print('[claimOneTimeKeys] claimKeysPayload $claimKeysPayload');

      // claim one time keys from matrix server
      final Map claimKeysResponse = await MatrixApi.claimKeys(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        oneTimeKeys: claimKeysPayload,
      );

      if (claimKeysResponse['errcode'] != null ||
          claimKeysResponse['failures'].isNotEmpty) {
        throw claimKeysResponse['error'];
      }

      print('[claimOneTimeKeys] claimKeysResponse $claimKeysResponse');

      // format oneTimeKey map from keys claimed in response
      Map<String, OneTimeKey> oneTimekeys = {};
      final oneTimeKeysClaimed = claimKeysResponse['one_time_keys'];
      oneTimeKeysClaimed.forEach((userId, deviceOneTimeKeys) {
        deviceOneTimeKeys.forEach((deviceId, Map oneTimeKey) {
          final String oneTimeKeyIdentity = oneTimeKey.keys.elementAt(0);
          final String oneTimeKeyHash = oneTimeKey.values.elementAt(0)['key'];

          final Map<String, String> oneTimeKeySignature =
              oneTimeKey[oneTimeKeyIdentity]['signatures'][userId];

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

      // synchronous cache of one time keys
      store.dispatch(setOneTimeKeysClaimed(oneTimekeys));

      // create sessions from new one time keys per device id
      oneTimekeys.forEach((deviceId, oneTimeKey) {
        final userId = oneTimeKey.userId;
        final deviceKey = store.state.cryptoStore.deviceKeys[userId][deviceId];

        store.dispatch(createOutboundKeySession(
          deviceId: deviceId,
          identityKey: deviceKey.keys['${Algorithms.curve25591}:$deviceId'],
          oneTimeKey: oneTimeKey.keys.values.elementAt(0),
        ));
      });
      return true;
    } catch (error) {
      store.dispatch(
        addAlert(
          type: 'warning',
          message: error.message,
          origin: 'claimOneTimeKeys',
        ),
      );
      return false;
    }
  };
}

/**
 * 
 * Outbound Key Session Funcationality (sychronous)
 * 
 * https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#starting-an-olm-session
 * https://matrix.org/docs/spec/client_server/latest#m-room-key
 * https://matrix.org/docs/spec/client_server/latest#m-olm-v1-curve25519-aes-sha2
 * https://matrix.org/docs/spec/client_server/r0.4.0#m-olm-v1-curve25519-aes-sha2
 * 
 */
ThunkAction<AppState> createOutboundKeySession({
  String deviceId,
  String identityKey,
  String oneTimeKey,
}) {
  return (Store<AppState> store) {
    final outboundKeySession = olm.Session();

    final account = store.state.cryptoStore.olmAccount;

    print('[createOutboundKeySession] $deviceId, $identityKey, $oneTimeKey');

    outboundKeySession.create_outbound(account, identityKey, oneTimeKey);

    print('[createOutboundKeySession] create outbound success');

    // sychronous
    store.dispatch(saveOutboundKeySession(
      identityKey: identityKey,
      session: outboundKeySession.pickle(deviceId),
    ));

    // send back a serialized version
    return outboundKeySession.pickle(deviceId);
  };
}

ThunkAction<AppState> saveOutboundKeySession({
  String identityKey,
  String session,
}) {
  return (Store<AppState> store) {
    store.dispatch(AddOutboundKeySession(
      session: session,
      identityKey: identityKey,
    ));
  };
}

ThunkAction<AppState> saveInboundKeySession({
  String identityKey,
  String session,
}) {
  return (Store<AppState> store) {
    store.dispatch(AddInboundKeySession(
      session: session,
      identityKey: identityKey,
    ));
  };
}

/**
 * 
 * https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#molmv1curve25519-aes-sha2
 */
ThunkAction<AppState> loadKeySession({
  String identityKey, // sender_key
  String type,
  String body,
}) {
  return (Store<AppState> store) async {
    try {
      var inboundKeySessionSerialized =
          store.state.cryptoStore.inboundKeySessions[identityKey];

      if (inboundKeySessionSerialized != null) {
        print(
          '[loadKeySession] found inboundKeySessionSerialized ${identityKey}',
        );

        final inboundKeySession = olm.Session()
          ..unpickle(identityKey, inboundKeySessionSerialized);

        // This returns a flag indicating whether the message was encrypted using that session.
        final inboundkeySessionMatch =
            inboundKeySession.matches_inbound_from(identityKey, body);

        print(
          '[loadKeySession] found session matches existing ${inboundkeySessionMatch}',
        );

        if (inboundkeySessionMatch) {
          return inboundKeySession;
        }
      }

      try {
        var outboundKeySessionSerialized =
            store.state.cryptoStore.outboundKeySessions[identityKey];

        if (outboundKeySessionSerialized != null) {
          print(
            '[loadKeySession] found outboundKeySessionSerialized ${identityKey}',
          );
          return olm.Session()
            ..unpickle(identityKey, outboundKeySessionSerialized);
        }
      } catch (error) {
        print('[loadKeySession] ${identityKey} ${error}');
      }

      // TODO: check here if the session + body actually match any other inboundKeySessions
      if (int.parse(type) == 0) {
        final newKeySession = olm.Session();
        final account = store.state.cryptoStore.olmAccount;

        print(
          '[loadKeySession] type ${type}: creating new inboundKeySession ${identityKey},${body}',
        );

        // Call olm_create_inbound_session_from using the olm account, and the sender_key and body of the message.
        newKeySession.create_inbound_from(account, identityKey, body);

        print(
          '[loadKeySession] created session successfully',
        );

        // that the same one-time-key from the sender cannot be reused.
        account.remove_one_time_keys(newKeySession);

        // Save sessions as needed
        await store.dispatch(saveOlmAccount());
        await store.dispatch(saveInboundKeySession(
          session: newKeySession.pickle(identityKey),
          identityKey: identityKey,
        ));

        // Return new key session
        return newKeySession;
      }
    } catch (error) {
      print('[loadKeySession] error ${identityKey} ${error}');
    }

    return null;
  };
}

/**
 * 
 * Outbound Message Session Functionality
 * 
 * https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#starting-a-megolm-session
 */
ThunkAction<AppState> createOutboundMessageSession({String roomId}) {
  return (Store<AppState> store) async {
    final outboundGroupSession = olm.OutboundGroupSession();

    outboundGroupSession.create();
    outboundGroupSession.session_id();
    outboundGroupSession.session_key();

    store.dispatch(saveOutboundMessageSession(
      roomId: roomId,
      session: outboundGroupSession.pickle(roomId),
    ));

    // send back a serialized version
    return outboundGroupSession.pickle(roomId);
  };
}

ThunkAction<AppState> saveOutboundMessageSession({
  String roomId,
  String session,
}) {
  return (Store<AppState> store) async {
    store.dispatch(
      AddOutboundMessageSession(roomId: roomId, session: session),
    );
  };
}

ThunkAction<AppState> loadOutboundMessageSession({String roomId}) {
  return (Store<AppState> store) async {
    final outboundMessageSessions =
        store.state.cryptoStore.outboundMessageSessions;

    var outboundMessageSessionSerialized = outboundMessageSessions[roomId];

    if (outboundMessageSessionSerialized == null) {
      outboundMessageSessionSerialized = await store.dispatch(
        createOutboundMessageSession(roomId: roomId),
      );
    }

    final session = olm.OutboundGroupSession();
    session.unpickle(roomId, outboundMessageSessionSerialized);
    return session;
  };
}

ThunkAction<AppState> exportMessageSession({String roomId}) {
  return (Store<AppState> store) async {
    final olm.OutboundGroupSession outboundMessageSession =
        await store.dispatch(
      loadOutboundMessageSession(roomId: roomId),
    );

    return {
      'session_id': outboundMessageSession.session_id(),
      'session_key': outboundMessageSession.session_key()
    };
  };
}

/**
 * 
 * Fetch Keys
 */
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

      final fileName = '${directory.path}/app_key_export_$formattedTime.json';

      var file = File(fileName);

      final user = store.state.authStore.user;
      final deviceKey = store.state.cryptoStore.deviceKeysOwned[user.deviceId];

      var exportData = {
        'account_key': store.state.cryptoStore.olmAccountKey,
        'device_keys': deviceKey.toMap(),
      };

      file = await file.writeAsString(json.encode(exportData));
    } catch (error) {
      store.dispatch(addAlert(
        type: 'warning',
        message: error,
        origin: 'exportDeviceKeysOwned',
      ));
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
      store.dispatch(addAlert(
        type: 'warning',
        message: error,
        origin: 'importDeviceKeysOwned',
      ));
    }
  };
}
