import 'dart:convert';

import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/events/model.dart';
import 'package:canonical_json/canonical_json.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:olm/olm.dart' as olm;

/**
 * Sync Device
 * 
 * Saves and converts events from /sync in regards to 
 * key sharing and other encryption events
 * 
 * TODO: combine these actions on the first pass
 */
ThunkAction<AppState> syncDevice(Map dataToDevice) {
  return (Store<AppState> store) async {
    try {
      // Extract the new events
      final List<dynamic> eventsToDevice = dataToDevice['events'];

      // Parse and decrypt necessary events
      final eventToDeviceActions = eventsToDevice.map((event) async {
        final eventType = event['type'];

        switch (eventType) {
          case EventTypes.encrypted:
            return await store.dispatch(
              decryptKeyContent(event: event),
            );
          default:
            return event;
        }
      });

      // Parse and decrypt necessary events
      final eventsFiltered = await Future.wait(eventToDeviceActions);

      // Parse and save necessary data from decrypted events
      final eventsFilteredActions = eventsFiltered.map((event) async {
        final eventType = event['type'];
        switch (eventType) {
          case EventTypes.roomKey:
            return await store.dispatch(
              saveSessionKey(event: event),
            );
          default:
            return event;
        }
      });

      await Future.wait(eventsFilteredActions);
    } catch (error) {
      store.dispatch(addAlert(
        type: 'warning',
        message: error,
        origin: 'syncDevice',
      ));
    }
  };
}

/**
 * Encrypt event content with loaded outbound session for room
 * 
 * https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#sending-an-encrypted-message-event
 */
ThunkAction<AppState> encryptMessageContent({
  String roomId,
  String eventType = EventTypes.message,
  Map content,
}) {
  return (Store<AppState> store) async {
    print('[encryptMessageContent] $roomId $eventType $content');

    // Load and deserialize session
    final olm.OutboundGroupSession outboundMessageSession =
        await store.dispatch(loadOutboundMessageSession(roomId: roomId));

    // Create payload for encryption per spe
    final payload = {
      'type': eventType,
      'content': content,
      'room_id': roomId,
    };

    // Canoncially encode the json for encryption
    final encodedPayload = canonicalJson.encode(payload);
    final serializedPayload = utf8.decode(encodedPayload);
    final encryptedPayload = outboundMessageSession.encrypt(serializedPayload);
    print('[encryptMessageContent] $encryptedPayload');

    // Save the outbound session after processing content
    await store.dispatch(saveOutboundMessageSession(
      roomId: roomId,
      session: outboundMessageSession.pickle(roomId),
    ));

    // Pull identity keys out of olm account
    final olmAccount = store.state.cryptoStore.olmAccount;
    final keys = json.decode(olmAccount.identity_keys());

    // Return the content to be sent or processed
    return {
      'sender_key': keys[Algorithms.curve25591],
      'ciphertext': encryptedPayload,
      'session_id': outboundMessageSession.session_id()
    };
  };
}

/**
 * Encrypt event content with loaded outbound session for a device
 * 
 * NOTE: Utilizes available one time keys pre-fetched 
 * and claimed by the current user
 * 
 * https://matrix.org/docs/spec/client_server/latest#m-room-encrypted
 */
ThunkAction<AppState> encryptKeyContent({
  String roomId,
  String identityKey,
  String eventType = EventTypes.roomKey,
  Map content,
}) {
  return (Store<AppState> store) async {
    // Create payload for encryption per spe
    final payload = {
      'type': eventType,
      'content': content,
      'room_id': roomId,
    };

    // All olm sessions should already be created
    // before sending a room key event to devices
    // Load and deserialize session
    final olm.Session outboundKeySession = await store.dispatch(
      loadKeySession(identityKey: identityKey),
    );

    // Canoncially encode the json for encryption
    final encodedPayload = canonicalJson.encode(payload);
    final serializedPayload = utf8.decode(encodedPayload);
    final encryptedPayload = outboundKeySession.encrypt(serializedPayload);

    // Save the outbound session after processing content
    await store.dispatch(saveOutboundKeySession(
      identityKey: identityKey,
      session: outboundKeySession.pickle(roomId),
    ));

    // Pull current user identity keys out of olm account
    final olmAccount = store.state.cryptoStore.olmAccount;
    final keys = json.decode(olmAccount.identity_keys());

    // Return the content to be sent or processed
    if (encryptedPayload.type == 0) {
      return {
        'sender_key': keys[Algorithms.curve25591], // current user identity key
        'ciphertext': {
          // receiver identity key
          identityKey: {
            'body': encryptedPayload.body,
            'type': encryptedPayload.type,
          }
        },
        'session_id': outboundKeySession.session_id()
      };
    }

    return {
      'sender_key': keys[Algorithms.curve25591],
      'ciphertext': encryptedPayload.body,
      'session_id': outboundKeySession.session_id()
    };
  };
}

/**
 * Decrypting toDevice event content with loaded 
 * key session (outbound | inbound) for that device
 * 
 * NOTE: Utilizes available one time keys pre-fetched 
 * and claimed by the current user
 * 
 * https://matrix.org/docs/spec/client_server/latest#m-room-encrypted
 */
ThunkAction<AppState> decryptKeyContent({
  Map event,
}) {
  return (Store<AppState> store) async {
    final deviceKeysOwned = store.state.cryptoStore.deviceKeysOwned;
    final deviceId = store.state.authStore.user.deviceId;
    final deviceKey = deviceKeysOwned[deviceId];

    final deviceKeyId = '${Algorithms.curve25591}:$deviceId';
    final currentIdentityKey = deviceKey.keys[deviceKeyId];

    print('[decryptKeyContent] $deviceKeyId $currentIdentityKey');

    // Extract the payload meant for this device by identity
    final Map content = event['content'];
    final String identityKey = content['sender_key'];
    final ciphertextContent = content['ciphertext'][currentIdentityKey];

    // Load and deserialize or create session
    final olm.Session keySession = await store.dispatch(
      loadKeySession(
        identityKey: identityKey,
        type: ciphertextContent['type'],
        body: ciphertextContent['body'],
      ),
    );

    // Decrypt the payload with the session for device identity
    final decryptedPayload = keySession.decrypt(
      ciphertextContent['type'],
      ciphertextContent['body'],
    );

    // Return the content to be sent or processed
    return json.decode(decryptedPayload);
  };
}

/**
 * Saving a message session key from a m.room_key event
 * 
 * https://matrix.org/docs/spec/client_server/latest#m-room-encrypted
 */
ThunkAction<AppState> saveSessionKey({
  Map event = const {
    "content": {
      "algorithm": "m.megolm.v1.aes-sha2",
      "room_id": "!OXolesDwApoFSnipLA:matrix.org",
      "session_id": "MFgUVsIJtzKrl1tJdLC+yipG/uTIF5sBXd8NvvLjfQ4",
      "session_key":
          "AgAAAADzfWWrH9BwIuCIiNWf2leSccMW3+OvC3QPKJp0OeSe2uwTf9Dm26Cp3aiaSyTM2nPEOJlAUaVOgLUqikubqI7Aq4p0IQ9QCJ5iHsbGk7xBQ2YnCpinbyybWUYEfBBFTW7wxYp8wbKSNh+dxo6ZTH3imXruFlh+cU8nGX7oG0duLDBYFFbCCbcyq5dbSXSwvsoqRv7kyBebAV3fDb7y430OQCWgLJfvhcKKnkJPI/j0w80vnzlojR4ZTtCc1FMTB1nAcrjZfzYOcwztQbfUTMcQeuudwxIgpCRfdJzUYJbmDQ"
    },
    "room_id": "!OXolesDwApoFSnipLA:matrix.org",
    "type": "m.room_key"
  },
}) {
  return (Store<AppState> store) async {
    // Extract the payload meant for this device by identity
    final String roomId = event['room_id'];
    final Map content = event['content'];

    // Load and deserialize or create session
    await store.dispatch(
      createInboundMessageSession(
        roomId: roomId,
        sessionKey: content['session_key'],
      ),
    );
  };
}
