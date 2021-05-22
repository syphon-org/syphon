// Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
// import 'package:canonical_json/canonical_json.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'package:intl/intl.dart';
import 'package:olm/olm.dart' as olm;
import 'package:path_provider/path_provider.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/algos.dart';
import 'package:syphon/global/libs/matrix/constants.dart';

// Project imports:
import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/crypto/events/actions.dart';
import 'package:syphon/store/crypto/keys/model.dart';
import 'package:syphon/store/crypto/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/user/model.dart';

/**
 * 
 * E2EE
 * https://matrix.org/docs/spec/client_server/latest#id76
 * 
 * Outbound Key Session === Outbound Session (Algorithm.olmv1)
 * Outbound Message Session === Outbound Group Session (Algorithm.megolmv2)
 */

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
  var oneTimeKeysCounts;
  SetOneTimeKeysCounts({this.oneTimeKeysCounts});
}

class SetOneTimeKeysClaimed {
  var oneTimeKeys;
  SetOneTimeKeysClaimed({this.oneTimeKeys});
}

class AddOutboundKeySession {
  String? identityKey;
  String? session;
  AddOutboundKeySession({this.identityKey, this.session});
}

class AddInboundKeySession {
  String? identityKey;
  String? session;
  AddInboundKeySession({this.identityKey, this.session});
}

class AddOutboundMessageSession {
  String? roomId;
  String? session;
  AddOutboundMessageSession({
    this.roomId,
    this.session,
  });
}

class UpdateMessageSessionOutbound {
  String? roomId;
  String? session;
  int? messageIndex;

  UpdateMessageSessionOutbound({
    this.roomId,
    this.session,
    this.messageIndex,
  });
}

class AddInboundMessageSession {
  String? roomId;
  String? identityKey;
  String? session;
  int? messageIndex;
  AddInboundMessageSession({
    this.roomId,
    this.identityKey,
    this.session,
    this.messageIndex,
  });
}

class DEBUGSetOutboundMessageSessionMap {
  String? nothing;
  DEBUGSetOutboundMessageSessionMap({this.nothing});
}

class ResetCrypto {}

/**
 * Helper Actions
 */
ThunkAction<AppState> setDeviceKeysOwned(Map deviceKeys) {
  return (Store<AppState> store) async {
    Map<String, DeviceKey> currentKeys = Map.from(
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
  return (Store<AppState> store) async {
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

      // create new olm account since none exists
      if (olmAccountKey == null) {
        olmAccount.create();
        final olmAccountKey = olmAccount.pickle(deviceId!);

        store.dispatch(SetOlmAccountBackup(olmAccountKey: olmAccountKey));
        store.dispatch(SetOlmAccount(olmAccount: olmAccount));
        await store.dispatch(saveOlmAccount());
      } else {
        // deserialize stored account since one exists
        olmAccount.unpickle(deviceId!, olmAccountKey);

        store.dispatch(SetOlmAccount(olmAccount: olmAccount));
      }
    } catch (error) {
      debugPrint('[initOlmEncryption] $error');
    }
  };
}

/**
 * Init Key Encryption
 */
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

/**
 * Save Olm Account
 * 
 * serialize and save the olm account being used
 * for identity and encryption
 */
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
      // fingerprint keypair - ed25519
      final fingerprintKeyName = '${Algorithms.ed25519}:${authUser.deviceId}';

      // identity key pair - curve25519
      final identityKeyName = '${Algorithms.curve25591}:${authUser.deviceId}';

      // formatting json for the signature required by matrix
      final deviceIdentityKeys = {
        'algorithms': [
          Algorithms.olmv1,
          Algorithms.megolmv1,
        ],
        'device_id': authUser.deviceId,
        'keys': {
          fingerprintKeyName: identityKeys[Algorithms.ed25519],
          identityKeyName: identityKeys[Algorithms.curve25591],
        },
        'user_id': authUser.userId,
      };

      // figerprint signature key pair generation for upload
      // warn: seems to work without canonical_json lib
      // utf8.decode(deviceKeysEncoded);
      final deviceKeysEncoded = json.encode(deviceIdentityKeys);
      final deviceKeysSerialized = deviceKeysEncoded;
      final deviceKeysSigned = olmAccount.sign(deviceKeysSerialized);

      var deviceKeysPayload = {'device_keys': deviceIdentityKeys};

      deviceKeysPayload['device_keys']!['signatures'] = {
        authUser.userId: {
          fingerprintKeyName: deviceKeysSigned,
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
      debugPrint('[generateIdentityKeys] $error');
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

/**
 * Generate One Time Keys
 * 
 * Returns the keys as a map
 */
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
    final olmAccount = store.state.cryptoStore.olmAccount;
    final authUser = store.state.authStore.user;

    final oneTimeKeysSignedAll = {};

    // Signing Keys
    oneTimeKeys!.forEach((key, value) {
      final oneTimeKey = {'key': value};

      // sign one time keys
      // TODO: CONFIRM WORKS WITHOUT CANONICAL JSON
      final oneTimeKeyEncoded = json.encode(oneTimeKey);
      //utf8.decode(oneTimeKeyEncoded);
      final oneTimeKeySerialized = oneTimeKeyEncoded;
      final oneTimeKeySigned = olmAccount!.sign(oneTimeKeySerialized);

      // add one time key in new keys map only
      final keyId = key.split(':')[0];
      final oneTimeKeyId = '${Algorithms.signedcurve25519}:$keyId';
      oneTimeKeysSignedAll[oneTimeKeyId] = {'key': value};

      // append signature for new signed key
      oneTimeKeysSignedAll[oneTimeKeyId]['signatures'] = {
        authUser.userId: {
          '${Algorithms.ed25519}:${authUser.deviceId}': oneTimeKeySigned,
        }
      };
    });

    return oneTimeKeysSignedAll;
  };
}

ThunkAction<AppState> updateOneTimeKeyCounts(
  Map<String, int> oneTimeKeysCounts,
) {
  return (Store<AppState> store) async {
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

    // if the key count hasn't changed, don't update it
    final currentKeyCount = store.state.cryptoStore.oneTimeKeysCounts;

    if (currentKeyCount[Algorithms.signedcurve25519] ==
            oneTimeKeysCounts[Algorithms.signedcurve25519] &&
        currentKeyCount.isNotEmpty) {
      return;
    }

    store.dispatch(SetOneTimeKeysCounts(
      oneTimeKeysCounts: oneTimeKeysCounts,
    ));

    // register new key counts
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

      // save account state after successful upload
      olmAccount.mark_keys_as_published();
      await store.dispatch(saveOlmAccount());

      // register new key counts
      store.dispatch(updateOneTimeKeyCounts(
        Map<String, int>.from(data['one_time_key_counts']),
      ));
    } catch (error) {
      store.dispatch(addAlert(error: error, origin: 'updateOneTimeKeys'));
    }
  };
}

/**
 * Update Key Sharing Sessions
 * 
 * Specifically for sending encrypted keys using olm
 * for later use with encrypted messages using megolm
 * sent directly to devices within the room
 * 
 * https://matrix.org/docs/spec/client_server/latest#id454
 * https://matrix.org/docs/spec/client_server/latest#id461
 */
ThunkAction<AppState> updateKeySessions({
  required Room room,
}) {
  return (Store<AppState> store) async {
    try {
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

      // manage which devices to claim oneTimeKeys for
      // here instead of within the function, because you'll
      // need to cycle through those necessary devices here anyway
      // for now, we're just sending the request to all the
      // one time keys that were saved from this call
      // global mutatable, this is real bad
      await store.dispatch(claimOneTimeKeys(room: room));
      final oneTimeKeys = store.state.cryptoStore.oneTimeKeysClaimed;

      // For each one time key claimed
      // send a m.room_key event directly to each device
      final List<OneTimeKey> devicesOneTimeKeys = List.from(oneTimeKeys.values);

      final requestsSendToDevicee = devicesOneTimeKeys.map(
        (oneTimeKey) async {
          try {
            // find the identityKey for the device
            final deviceKey = store.state.cryptoStore
                .deviceKeys[oneTimeKey.userId!]![oneTimeKey.deviceId!]!;

            // Poorly decided to save key sessions by deviceId at first but then
            // realised that you may have the same identityKey for diff
            // devices and you also don't have the device id in the
            // toDevice event payload -__-, convert back to identity key
            final roomKeyEventEncrypted = await store.dispatch(
              encryptKeyContent(
                roomId: room.id,
                recipient: deviceKey.userId,
                recipientKeys: deviceKey,
                eventType: EventTypes.roomKey,
                content: roomKeyEventContent,
              ),
            );

            // format payload for toDevice events
            final payload = {
              '${deviceKey.userId}': {
                '${deviceKey.deviceId}': roomKeyEventEncrypted,
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

            debugPrint(
              '[sendEventToDevice] COMPLETED ${randomNumber} ${store.state.authStore.protocol}${store.state.authStore.user.homeserver}',
            );

            printJson(response);

            if (response['errcode'] != null) {
              throw response['error'];
            }

            debugPrint('[sendSessionKeys] success!');
          } catch (error) {
            debugPrint('[sendSessionKeys] $error');
          }
        },
      );

      // await all sendToDevice room key events to be sent to users
      await Future.wait(requestsSendToDevicee);
      await store.dispatch(setOneTimeKeysClaimed({}));
    } catch (error) {
      store.dispatch(addAlert(
          origin: "updateKeySessions",
          message: error.toString(),
          error: error));
    }
  };
}

///
/// Claims keys for devices and creates key sharing session
///
ThunkAction<AppState> claimOneTimeKeys({
  required Room room,
}) {
  return (Store<AppState> store) async {
    try {
      final roomUserIds = room.userIds;
      final deviceKeys = store.state.cryptoStore.deviceKeys;
      final outboundKeySessions = store.state.cryptoStore.outboundKeySessions;
      final currentUser = store.state.authStore.user;

      // get deviceKeys for every user present in the chat
      final List<DeviceKey> roomDeviceKeys = List.from(roomUserIds
          .map((userId) => (deviceKeys[userId] ?? {}).values)
          .expand((x) => x));

      // Create a map of all the oneTimeKeys to claim
      final claimKeysPayload = roomDeviceKeys.fold(
        Map.from({}),
        (dynamic claims, deviceKey) {
          // don't claim your own device one time keys
          if (deviceKey.deviceId == currentUser.deviceId) return claims;

          // find the identityKey for the device
          final keyId = Keys.identity(deviceId: deviceKey.deviceId);
          final identityKey = deviceKey.keys![keyId];

          // don't claim one time keys for already claimed devices
          if (outboundKeySessions.containsKey(identityKey)) return claims;

          if (claims[deviceKey.userId] == null) {
            claims[deviceKey.userId] = {};
          }

          claims[deviceKey.userId][deviceKey.deviceId] =
              Algorithms.signedcurve25519;

          return claims;
        },
      );

      // stop if one time keys for known devices already exist
      if (claimKeysPayload.isEmpty) {
        debugPrint(
          '[claimOneTimeKeys] all key sharing sessions per device are ready',
        );
        return true;
      }

      debugPrint('[claimKeysPayload]');
      printJson(claimKeysPayload);

      debugPrint(
        '[sendEventToDevice] COMPLETED ${store.state.authStore.protocol}${store.state.authStore.user.homeserver}',
      );

      // claim one time keys from matrix server
      final Map claimKeysResponse = await MatrixApi.claimKeys(
        protocol: store.state.authStore.protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        oneTimeKeys: claimKeysPayload,
      );

      debugPrint('[claimKeysResponse]');
      printJson(claimKeysResponse);

      if (claimKeysResponse['errcode'] != null ||
          claimKeysResponse['failures'].isNotEmpty) {
        throw claimKeysResponse['error'];
      }

      // format oneTimeKey map from keys claimed in response
      Map<String, OneTimeKey> oneTimekeys = {};
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

      // cache of one time keys
      await store.dispatch(setOneTimeKeysClaimed(oneTimekeys));

      // create sessions from new one time keys per device id
      oneTimekeys.forEach((deviceId, oneTimeKey) {
        final userId = oneTimeKey.userId;
        final deviceKey =
            store.state.cryptoStore.deviceKeys[userId!]![deviceId]!;
        final keyId = Keys.identity(deviceId: deviceKey.deviceId);
        final identityKey = deviceKey.keys![keyId];

        store.dispatch(createKeySessionOutbound(
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

/**
 * 
 * Outbound Key Session Funcationality (synchronous)
 * 
 * https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#starting-an-olm-session
 * https://matrix.org/docs/spec/client_server/latest#m-room-key
 * https://matrix.org/docs/spec/client_server/latest#m-olm-v1-curve25519-aes-sha2
 * https://matrix.org/docs/spec/client_server/r0.4.0#m-olm-v1-curve25519-aes-sha2
 * 
 */
ThunkAction<AppState> createKeySessionOutbound({
  String? oneTimeKey,
  String? identityKey,
}) {
  return (Store<AppState> store) {
    final outboundKeySession = olm.Session();

    final account = store.state.cryptoStore.olmAccount!;

    outboundKeySession.create_outbound(account, identityKey!, oneTimeKey!);

    // Pickle by identity
    final serializedKeySession = outboundKeySession.pickle(identityKey);

    // sychronous
    store.dispatch(saveKeySessionOutbound(
      identityKey: identityKey,
      session: serializedKeySession,
    ));

    // send back a serialized version
    return serializedKeySession;
  };
}

ThunkAction<AppState> saveKeySessionOutbound({
  String? identityKey,
  String? session,
}) {
  return (Store<AppState> store) {
    store.dispatch(AddOutboundKeySession(
      session: session,
      identityKey: identityKey,
    ));
  };
}

ThunkAction<AppState> saveKeySessionInbound({
  String? session,
  String? identityKey,
}) {
  return (Store<AppState> store) {
    store.dispatch(AddInboundKeySession(
      session: session,
      identityKey: identityKey,
    ));
  };
}

ThunkAction<AppState> loadKeySessionOutbound({
  String? identityKey, // sender_key
}) {
  return (Store<AppState> store) async {
    try {
      var outboundKeySessionSerialized =
          store.state.cryptoStore.outboundKeySessions[identityKey!];

      // Deserialize outbound key session with device identity key
      if (outboundKeySessionSerialized != null) {
        final session = olm.Session();
        session.unpickle(
          identityKey,
          outboundKeySessionSerialized,
        );

        return session;
      }
    } catch (error) {
      debugPrint('[loadKeySessionOutbound] $error');
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
ThunkAction<AppState> loadKeySessionInbound({
  int? type,
  String? body,
  String? identityKey, // sender_key
}) {
  return (Store<AppState> store) async {
    try {
      // type 1 - attempt to decrypt with an existing session
      var inboundKeySessionSerialized =
          store.state.cryptoStore.inboundKeySessions[identityKey!];

      if (inboundKeySessionSerialized != null) {
        final inboundKeySession = olm.Session()
          ..unpickle(identityKey, inboundKeySessionSerialized);

        // This returns a flag indicating whether the message was encrypted using that session.
        final inboundkeySessionMatch =
            inboundKeySession.matches_inbound_from(identityKey, body!);

        if (inboundkeySessionMatch) {
          return inboundKeySession;
        }
      }
    } catch (error) {
      debugPrint('[loadKeySessionInbound] $error');
    }

    try {
      if (type == 0) {
        final newKeySession = olm.Session();
        final account = store.state.cryptoStore.olmAccount!;

        // Call olm_create_inbound_session_from using the olm account, and the sender_key and body of the message.
        newKeySession.create_inbound_from(account, identityKey!, body!);

        // that the same one-time-key from the sender cannot be reused.
        account.remove_one_time_keys(newKeySession);

        // Save sessions as needed
        await store.dispatch(saveOlmAccount());
        await store.dispatch(saveKeySessionInbound(
          session: newKeySession.pickle(identityKey),
          identityKey: identityKey,
        ));

        // Return new key session
        return newKeySession;
      }
    } catch (error) {
      debugPrint('[loadKeySessionInbound] $error');
    }

    return null;
  };
}

/**
 * Inbound Message Session
 *  
 * https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#starting-a-megolm-session
 */
ThunkAction<AppState> createMessageSessionInbound({
  String? roomId,
  String? identityKey,
  String? sessionKey,
}) {
  return (Store<AppState> store) async {
    final inboundMessageSession = olm.InboundGroupSession();

    inboundMessageSession.create(sessionKey!);
    final messageIndex = inboundMessageSession.first_known_index();

    store.dispatch(AddInboundMessageSession(
      roomId: roomId,
      identityKey: identityKey,
      session: inboundMessageSession.pickle(roomId!),
      messageIndex: messageIndex,
    ));
  };
}

ThunkAction<AppState> loadMessageSessionInbound({
  String? roomId,
  String? identityKey,
}) {
  return (Store<AppState> store) async {
    final messageSessions =
        store.state.cryptoStore.inboundMessageSessions[roomId!];

    if (messageSessions == null || !messageSessions.containsKey(identityKey)) {
      throw 'Unable to find inbound message session for decryption';
    }

    final session = olm.InboundGroupSession();
    session.unpickle(roomId, messageSessions[identityKey!]!);
    return session;
  };
}

/**
 * 
 * Save Message Session Inbound
 * 
 * Saves the message session and index after encrypting and sending an event
 */
ThunkAction<AppState> saveMessageSessionInbound({
  String? roomId,
  String? identityKey,
  olm.InboundGroupSession? session,
  int? messageIndex,
}) {
  return (Store<AppState> store) async {
    return await store.dispatch(AddInboundMessageSession(
      roomId: roomId,
      identityKey: identityKey,
      session: session!.pickle(roomId!),
      messageIndex: messageIndex,
    ));
  };
}

/**
 * 
 * Outbound Message Session Functionality
 * 
 * https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#starting-a-megolm-session
 */
ThunkAction<AppState> createMessageSessionOutbound({String? roomId}) {
  return (Store<AppState> store) async {
    // Get current user device identity key
    final deviceId = store.state.authStore.user.deviceId;
    final deviceKeysOwned = store.state.cryptoStore.deviceKeysOwned;
    final deviceKey = deviceKeysOwned[deviceId!]!;
    final deviceKeyId = '${Algorithms.curve25591}:$deviceId';
    final identityKeyCurrent = deviceKey.keys![deviceKeyId];

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
      session: outboundMessageSession.pickle(roomId!),
    ));

    store.dispatch(AddInboundMessageSession(
      roomId: roomId,
      identityKey: identityKeyCurrent,
      session: inboundMessageSession.pickle(roomId),
      messageIndex: inboundMessageSession.first_known_index(),
    ));

    // send back a serialized version
    return outboundMessageSession.pickle(roomId);
  };
}

/**
 * TODO:
 * one would likely need more based on identity + device, 
 * assuming you've imported keys but lets keep it simple for alpha
 */
ThunkAction<AppState> loadMessageSessionOutbound({String? roomId}) {
  return (Store<AppState> store) async {
    // Load session for identity
    var outboundMessageSessionSerialized =
        store.state.cryptoStore.outboundMessageSessions[roomId!];

    if (outboundMessageSessionSerialized == null) {
      outboundMessageSessionSerialized = await store.dispatch(
        createMessageSessionOutbound(roomId: roomId),
      );
    }

    final session = olm.OutboundGroupSession();
    session.unpickle(roomId, outboundMessageSessionSerialized!);
    return session;
  };
}

ThunkAction<AppState> saveMessageSessionOutbound({
  String? roomId,
  String? session,
}) {
  return (Store<AppState> store) async {
    store.dispatch(
      AddOutboundMessageSession(
        roomId: roomId,
        session: session,
      ),
    );
  };
}

ThunkAction<AppState> exportMessageSession({String? roomId}) {
  return (Store<AppState> store) async {
    final olm.OutboundGroupSession outboundMessageSession =
        await store.dispatch(
      loadMessageSessionOutbound(roomId: roomId),
    );

    return {
      'session_id': outboundMessageSession.session_id(),
      'session_key': outboundMessageSession.session_key()
    };
  };
}

/**
 * 
 * Fetch Device Keys
 * 
 * fetches the keys uploaded to the matrix homeserver
 * by other users
 */
ThunkAction<AppState> fetchDeviceKeys({
  List<String?>? userIds,
}) {
  return (Store<AppState> store) async {
    try {
      final Map<String, dynamic> userIdMap = Map.fromIterable(
        userIds!,
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
      Map<String, Map<String, DeviceKey>> newDeviceKeys = {};

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

      final formattedTime =
          DateFormat('MMM_dd_yyyy_hh_mm_aa').format(currentTime).toLowerCase();

      final fileName = '${directory.path}/app_key_export_$formattedTime.json';

      var file = File(fileName);

      final user = store.state.authStore.user;
      final deviceKey =
          store.state.cryptoStore.deviceKeysOwned[user.deviceId!]!;

      var exportData = {
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
      FilePickerResult file = await (FilePicker.platform.pickFiles(
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
