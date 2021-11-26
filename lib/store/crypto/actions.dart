import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:canonical_json/canonical_json.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:olm/olm.dart' as olm;
import 'package:path_provider/path_provider.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/crypto/events/actions.dart';
import 'package:syphon/store/crypto/keys/model.dart';
import 'package:syphon/store/crypto/keys/selectors.dart';
import 'package:syphon/store/crypto/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/user/model.dart';

///
///
/// E2EE
/// https://matrix.org/docs/spec/client_server/latest#id76
///
/// Outbound Key Session === Outbound Session (Algorithm.olmv1)
/// Outbound Message Session === Outbound Group Session (Algorithm.megolmv2)
///
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

class SaveKeySession {
  String session;
  String sessionId;
  String identityKey;

  SaveKeySession({
    required this.session,
    required this.sessionId,
    required this.identityKey,
  });
}

class AddOutboundMessageSession {
  String roomId;
  String session;
  AddOutboundMessageSession({
    required this.roomId,
    required this.session,
  });
}

class UpdateMessageSessionOutbound {
  String roomId;
  String session;
  int? messageIndex;

  UpdateMessageSessionOutbound({
    required this.roomId,
    required this.session,
    this.messageIndex,
  });
}

class AddInboundMessageSession {
  String roomId;
  String identityKey;
  String session;
  int messageIndex;
  AddInboundMessageSession({
    required this.roomId,
    required this.identityKey,
    required this.session,
    required this.messageIndex,
  });
}

class ResetCrypto {}

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

ThunkAction<AppState> deleteDeviceKeys() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(ResetCrypto());
    } catch (error) {
      store.dispatch(addAlert(
        origin: 'deleteDeviceKeys',
        error: error,
      ));
    }
  };
}

///
/// Initing Olm Account
///
/// https://gitlab.matrix.org/matrix-org/olm/-/blob/master/python/olm/account.py
///
/// Uses deviceId to encrypt and serialize the account (pickle)
/// needed to know about the python library to know what that was
ThunkAction<AppState> initOlmEncryption(User user) {
  return (Store<AppState> store) async {
    try {
      await olm.init();
      final olmAccount = olm.Account();

      final deviceId = store.state.authStore.user.deviceId!;
      final olmAccountKey = store.state.cryptoStore.olmAccountKey;

      // create new olm account since none exists
      if (olmAccountKey == null) {
        olmAccount.create();
        final olmAccountKey = olmAccount.pickle(deviceId);

        store.dispatch(SetOlmAccountBackup(olmAccountKey: olmAccountKey));
        store.dispatch(SetOlmAccount(olmAccount: olmAccount));
        await store.dispatch(saveOlmAccount());
      } else {
        // deserialize stored account since one exists
        olmAccount.unpickle(deviceId, olmAccountKey);

        store.dispatch(SetOlmAccount(olmAccount: olmAccount));
      }
    } catch (error) {
      printError('[initOlmEncryption] $error');
    }
  };
}

/// Init Key Encryption
ThunkAction<AppState> initKeyEncryption(User user) {
  return (Store<AppState> store) async {
    // fetch device keys and pull out key based on device id
    final Map<String, DeviceKey> ownedDeviceKeys = await store.dispatch(
          fetchDeviceKeysOwned(user),
        ) ??
        {};

    await store.dispatch(initOlmEncryption(user));

    // check if key exists for this device
    if (!ownedDeviceKeys.containsKey(user.deviceId)) {
      // generate a key if none exist locally and remotely
      await store.dispatch(generateIdentityKeys());

      final deviceId = store.state.authStore.user.deviceId;
      final deviceKey = store.state.cryptoStore.deviceKeysOwned[deviceId];

      // upload the key intended for this device
      await store.dispatch(uploadIdentityKeys(deviceKey: deviceKey!));
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

/// Save Olm Account
///
/// serialize and save the olm account being used
/// for identity and encryption
ThunkAction<AppState> saveOlmAccount() {
  return (Store<AppState> store) async {
    try {
      final deviceId = store.state.authStore.user.deviceId!;
      final olmAccount = store.state.cryptoStore.olmAccount!;
      final olmAccountKey = olmAccount.pickle(deviceId);
      store.dispatch(SetOlmAccountBackup(olmAccountKey: olmAccountKey));
    } catch (error) {
      store.dispatch(
        addAlert(error: error, origin: 'saveOlmAccount'),
      );
    }
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
      store.dispatch(addAlert(error: error, origin: 'updateOneTimeKeys'));
    }
  };
}

/// Update Key Sharing Sessions
///
/// Specifically for sending encrypted keys using olm
/// for later use with encrypted messages using megolm
/// sent directly to devices within the room
///
/// https://matrix.org/docs/spec/client_server/latest#id454
/// https://matrix.org/docs/spec/client_server/latest#id461
ThunkAction<AppState> updateKeySessions({
  required Room room,
}) {
  return (Store<AppState> store) async {
    try {
      // Fetch and save any new user device keys for the room
      final roomUsersDeviceKeys = await store.dispatch(
        fetchDeviceKeys(userIds: room.userIds),
      );

      store.dispatch(setDeviceKeys(roomUsersDeviceKeys));

      // get deviceKeys for every user present in the chat
      final devicesWithoutMessageSessions = filterDevicesWithoutMessageSessions(
        store,
        room,
      );

      if (devicesWithoutMessageSessions.isEmpty) {
        printInfo('[updateKeySessions] all device sessions have a message session for room');
        return;
      }

      // Create payload of megolm session keys for message decryption
      final messageSession = await store.dispatch(
        exportMessageSession(roomId: room.id),
      );

      final roomKeyEventContent = {
        'algorithm': Algorithms.megolmv1,
        'room_id': room.id,
        'session_id': messageSession['session_id'],
        'session_key': messageSession['session_key'],
      };

      // get deviceKeys for every user present in the chat
      final devicesWithoutKeySessions = filterDevicesWithoutKeySessions(
        store,
        room,
      );

      // claim necessary one time keys and create and send outbound
      // Olm sessions for valid device keys without a key session
      await store.dispatch(claimOneTimeKeys(
        room: room,
        deviceKeys: devicesWithoutKeySessions,
      ));

      // await all sendToDevice room key events to be sent to users
      await Future.wait(devicesWithoutMessageSessions.map(
        (deviceKey) async {
          try {
            // Poorly decided to save key sessions by deviceId at first but then
            // realised that you may have the same identityKey for diff
            // devices and you also don't have the device id in the
            // toDevice event payload -__-, convert back to identity key
            final roomKeyEventEncrypted = await store.dispatch(
              encryptKeyContent(
                roomId: room.id,
                recipientKey: deviceKey,
                eventType: EventTypes.roomKey,
                content: roomKeyEventContent,
              ),
            );

            // format payload for toDevice events
            final payload = {
              deviceKey.userId: {
                deviceKey.deviceId: roomKeyEventEncrypted,
              },
            };

            final randomNumber = Random.secure().nextInt(1 << 31).toString();

            final response = await MatrixApi.sendEventToDevice(
              trxId: randomNumber,
              protocol: store.state.authStore.protocol,
              accessToken: store.state.authStore.user.accessToken,
              homeserver: store.state.authStore.user.homeserver,
              eventType: EventTypes.encrypted,
              content: payload,
            );

            if (response['errcode'] != null) {
              throw response['error'];
            }

            printInfo('[sendSessionKeys] success! $randomNumber');
          } catch (error) {
            printError('[sendSessionKeys] $error');
          }
        },
      ));
    } catch (error) {
      store
          .dispatch(addAlert(origin: 'updateKeySessions', message: error.toString(), error: error));
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
///
/// Key Session Management
///
/// https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#starting-an-olm-session
/// https://matrix.org/docs/spec/client_server/latest#m-room-key
/// https://matrix.org/docs/spec/client_server/latest#m-olm-v1-curve25519-aes-sha2
/// https://matrix.org/docs/spec/client_server/r0.4.0#m-olm-v1-curve25519-aes-sha2
///
///
ThunkAction<AppState> saveKeySession({
  required String session,
  required String sessionId,
  required String identityKey,
}) {
  return (Store<AppState> store) {
    store.dispatch(SaveKeySession(
      session: session,
      sessionId: sessionId,
      identityKey: identityKey,
    ));
  };
}

ThunkAction<AppState> createKeySessionOutbound({
  String? oneTimeKey,
  String? identityKey,
}) {
  return (Store<AppState> store) async {
    final outboundKeySession = olm.Session();

    final account = store.state.cryptoStore.olmAccount!;
    final deviceId = store.state.authStore.user.deviceId!;

    outboundKeySession.create_outbound(account, identityKey!, oneTimeKey!);

    // sychronous
    await store.dispatch(SaveKeySession(
      identityKey: identityKey,
      sessionId: outboundKeySession.session_id(),
      session: outboundKeySession.pickle(deviceId),
    ));

    await store.dispatch(saveOlmAccount());
  };
}

ThunkAction<AppState> loadKeySessionOutbound({
  required String identityKey, // sender_key
}) {
  return (Store<AppState> store) async {
    try {
      final deviceId = store.state.authStore.user.deviceId!;
      final keySessions = selectKeySessions(store, identityKey);

      printInfo('[loadKeySessionOutbound] checking outbounds for $identityKey');

      for (final session in keySessions.reversed) {
        try {
          // type 1 - attempt to decrypt with an existing sessions
          final keySession = olm.Session()..unpickle(deviceId, session);

          final keySessionId = keySession.session_id();

          final keySessionType = keySession.encrypt_message_type();

          printInfo(
              '[loadKeySessionOutbound] found $keySessionId for $identityKey of type $keySessionType');
          return keySession;
        } catch (error) {
          printInfo('[loadKeySessionOutbound] unsuccessful $identityKey $error');
        }
      }

      throw 'No valid sessions found $identityKey';
    } catch (error) {
      printError('[loadKeySessionOutbound] failure $identityKey $error');
      return null;
    }
  };
}

///
/// Load Key Session Inbound
///
/// Manage and load Olm sessions for pre-key messages or indications
///
/// https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#molmv1curve25519-aes-sha2
///
ThunkAction<AppState> loadKeySessionInbound({
  required int type,
  required String body,
  required String identityKey, // sender_key
}) {
  return (Store<AppState> store) async {
    final deviceId = store.state.authStore.user.deviceId!;

    // filter all key session saved under a certain identityKey
    final keySessions = selectKeySessions(store, identityKey);

    printInfo('[loadKeySessionInbound] checking known sessions for sender $identityKey');

    // reverse the list to attempt the latest first (LinkedHashMap will know)
    for (final session in keySessions.reversed) {
      try {
        // attempt to decrypt with any existing sessions
        final keySession = olm.Session()..unpickle(deviceId, session);
        final keySessionId = keySession.session_id();

        // this returns a flag indicating whether the message was encrypted using that session
        final keySessionMatch = keySession.matches_inbound(body);

        printInfo('[loadKeySessionInbound] $keySessionId session matched $keySessionMatch');

        if (keySessionMatch) {
          return keySession;
        }

        printInfo('[loadKeySessionInbound] $keySessionId attempting decryption');

        // attempt decryption in case its not a locally known inbound session state
        keySession.decrypt(type, body);

        printInfo('[loadKeySessionInbound] $keySessionId successfully decrypted');

        // Return a fresh key session having not decrypted the payload
        return olm.Session()..unpickle(deviceId, session);
      } catch (error) {
        printError('[loadKeySessionInbound] unsuccessful $error');
      }
    }

    try {
      // if type zero, and no other known sessions can decrypt, create a new one
      if (type == 0) {
        final newKeySession = olm.Session();
        final account = store.state.cryptoStore.olmAccount!;

        // Call olm_create_inbound_session_from using the olm account, and the sender_key and body of the message.
        newKeySession.create_inbound_from(account, identityKey, body);

        // that the same one-time-key from the sender cannot be reused.
        account.remove_one_time_keys(newKeySession);

        // Save sessions as needed
        await store.dispatch(saveOlmAccount());
        await store.dispatch(saveKeySession(
          identityKey: identityKey,
          sessionId: newKeySession.session_id(),
          session: newKeySession.pickle(deviceId),
        ));

        // Return new key session
        return newKeySession;
      }
    } catch (error) {
      printError('[loadKeySessionInbound] $error');
    }

    return null;
  };
}

/// Inbound Message Session
///
/// https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#starting-a-megolm-session
ThunkAction<AppState> createMessageSessionInbound({
  required String roomId,
  required String identityKey,
  required String sessionKey,
}) {
  return (Store<AppState> store) async {
    final inboundMessageSession = olm.InboundGroupSession();

    inboundMessageSession.create(sessionKey);
    final messageIndex = inboundMessageSession.first_known_index();

    store.dispatch(AddInboundMessageSession(
      roomId: roomId,
      identityKey: identityKey,
      messageIndex: messageIndex,
      session: inboundMessageSession.pickle(roomId),
    ));
  };
}

ThunkAction<AppState> loadMessageSessionInbound({
  required String roomId,
  required String identityKey,
}) {
  return (Store<AppState> store) async {
    final messageSessions = store.state.cryptoStore.inboundMessageSessions[roomId];

    if (messageSessions == null || !messageSessions.containsKey(identityKey)) {
      throw 'Unable to find inbound message session for decryption';
    }

    final messageSession = olm.InboundGroupSession();
    messageSession.unpickle(roomId, messageSessions[identityKey]!);
    return messageSession;
  };
}

///
/// Save Message Session Inbound
///
/// Saves the message session and index after encrypting and sending an event
ThunkAction<AppState> saveMessageSessionInbound({
  required String roomId,
  required String identityKey,
  required olm.InboundGroupSession session,
  required int messageIndex,
}) {
  return (Store<AppState> store) async {
    return await store.dispatch(AddInboundMessageSession(
      roomId: roomId,
      identityKey: identityKey,
      session: session.pickle(roomId),
      messageIndex: messageIndex,
    ));
  };
}

///
/// Outbound Message Session Functionality
///
/// https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#starting-a-megolm-session
ThunkAction<AppState> createMessageSessionOutbound({required String roomId}) {
  return (Store<AppState> store) async {
    // Get current user device identity key
    final deviceId = store.state.authStore.user.deviceId;
    final deviceKeysOwned = store.state.cryptoStore.deviceKeysOwned;

    final currentDeviceKey = deviceKeysOwned[deviceId!]!;

    final identityKeyId = Keys.identityKeyId(deviceId: deviceId);

    final identityKey = currentDeviceKey.keys![identityKeyId];

    if (identityKey == null) {
      throw 'Failed to extract identityKey for this session';
    }

    final outboundMessageSession = olm.OutboundGroupSession();
    final inboundMessageSession = olm.InboundGroupSession();

    outboundMessageSession.create();
    final session = {
      'session_id': outboundMessageSession.session_id(),
      'session_key': outboundMessageSession.session_key(),
    };

    inboundMessageSession.create(session['session_key']!);

    store.dispatch(AddOutboundMessageSession(
      roomId: roomId,
      session: outboundMessageSession.pickle(roomId),
    ));

    store.dispatch(AddInboundMessageSession(
      roomId: roomId,
      identityKey: identityKey,
      session: inboundMessageSession.pickle(roomId),
      messageIndex: inboundMessageSession.first_known_index(),
    ));

    // send back a serialized version
    return outboundMessageSession.pickle(roomId);
  };
}

///
/// Load Message Session Outbound
///
/// TODO: potentially convert to identity + device similar to inbound
///
ThunkAction<AppState> loadMessageSessionOutbound({String? roomId}) {
  return (Store<AppState> store) async {
    // Load session for identity
    var outboundMessageSessionSerialized = store.state.cryptoStore.outboundMessageSessions[roomId!];

    if (outboundMessageSessionSerialized == null) {
      outboundMessageSessionSerialized = await store.dispatch(
        createMessageSessionOutbound(roomId: roomId),
      );
    }

    final messageSession = olm.OutboundGroupSession();
    messageSession.unpickle(roomId, outboundMessageSessionSerialized!);
    return messageSession;
  };
}

ThunkAction<AppState> saveMessageSessionOutbound({
  required String roomId,
  required String session,
}) {
  return (Store<AppState> store) async {
    store.dispatch(AddOutboundMessageSession(
      roomId: roomId,
      session: session,
    ));
  };
}

ThunkAction<AppState> exportMessageSession({String? roomId}) {
  return (Store<AppState> store) async {
    final olm.OutboundGroupSession outboundMessageSession = await store.dispatch(
      loadMessageSessionOutbound(roomId: roomId),
    );

    return {
      'session_id': outboundMessageSession.session_id(),
      'session_key': outboundMessageSession.session_key()
    };
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

ThunkAction<AppState> exportDeviceKeysOwned() {
  return (Store<AppState> store) async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      final currentTime = DateTime.now();

      final formattedTime = DateFormat('MMM_dd_yyyy_hh_mm_aa').format(currentTime).toLowerCase();

      final fileName = '${directory.path}/app_key_export_$formattedTime.json';

      var file = File(fileName);

      final user = store.state.authStore.user;
      final deviceKey = store.state.cryptoStore.deviceKeysOwned[user.deviceId!]!;

      final exportData = {
        'account_key': store.state.cryptoStore.olmAccountKey,
        'device_keys': deviceKey.toMatrix(),
      };

      file = await file.writeAsString(json.encode(exportData));
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        origin: 'exportDeviceKeysOwned',
      ));
    }
  };
}

ThunkAction<AppState> importDeviceKeysOwned() {
  return (Store<AppState> store) async {
    try {
      final authUser = store.state.authStore.user;
      final FilePickerResult file = await (FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['.json'],
      ) as Future<FilePickerResult>);

      final File keyFile = File(file.paths[0]!);

      final importData = await json.decode(await keyFile.readAsString());

      store.dispatch(
        SetOlmAccountBackup(
          olmAccountKey: importData['account_key'],
        ),
      );

      store.dispatch(
        SetDeviceKeysOwned(
          deviceKeysOwned: {
            authUser.deviceId!: DeviceKey.fromMatrix(
              importData['device_keys'],
            ),
          },
        ),
      );
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        origin: 'importDeviceKeysOwned',
      ));
    }
  };
}
