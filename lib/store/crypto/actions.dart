import 'dart:async';
import 'dart:math';

import 'package:olm/olm.dart' as olm;
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/crypto/events/actions.dart';
import 'package:syphon/store/crypto/keys/actions.dart';
import 'package:syphon/store/crypto/keys/models.dart';
import 'package:syphon/store/crypto/keys/selectors.dart';
import 'package:syphon/store/crypto/sessions/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/user/model.dart';

///
///
/// E2EE
/// https://matrix.org/docs/spec/client_server/latest#id76
///
///
///
// Set currently authenticated users keys
class SetOlmAccount {
  var olmAccount;
  SetOlmAccount({this.olmAccount});
}

class SetOlmAccountBackup {
  var olmAccountKey;
  SetOlmAccountBackup({this.olmAccountKey});
}

class ResetCrypto {}

ThunkAction<AppState> resetSessionKeys() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(ResetCrypto());
    } catch (error) {
      store.dispatch(addAlert(
        origin: 'resetSessionKeys',
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

///
/// Update (Pre)Key Sessions
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
