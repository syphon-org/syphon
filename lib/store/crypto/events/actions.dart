// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
// import 'package:canonical_json/canonical_json.dart';
import 'package:olm/olm.dart' as olm;
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/algos.dart';

// Project imports:
import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/crypto/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/rooms/actions.dart';

/**
 * Encrypt event content with loaded outbound session for room
 * 
 * https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#sending-an-encrypted-message-event
 */
ThunkAction<AppState> encryptMessageContent({
  String? roomId,
  String eventType = EventTypes.message,
  Map? content,
}) {
  return (Store<AppState> store) async {
    // Load and deserialize session
    final olm.OutboundGroupSession outboundMessageSession =
        await store.dispatch(
      loadMessageSessionOutbound(roomId: roomId),
    );

    // Create payload for encryption per spec
    final payload = {
      'type': eventType,
      'content': content,
      'room_id': roomId,
    };

    // Encode the json for encryption
    final serializedPayload = json.encode(payload);
    final encryptedPayload = outboundMessageSession.encrypt(serializedPayload);

    // save the outbound session after processing content
    await store.dispatch(saveMessageSessionOutbound(
      roomId: roomId,
      session: outboundMessageSession.pickle(roomId!),
    ));

    // Pull identity keys out of olm account
    final olmAccount = store.state.cryptoStore.olmAccount!;
    final keys = json.decode(olmAccount.identity_keys());
    final sessionId = outboundMessageSession.session_id();

    // Return the content to be sent or processed
    return {
      'sender_key': keys[Algorithms.curve25591],
      'ciphertext': encryptedPayload,
      'session_id': sessionId,
    };
  };
}

/**
 * Decrypt event content with loaded inbound|outbound session for room
 * 
 * https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#sending-an-encrypted-message-event
 */
ThunkAction<AppState> decryptMessageEvent({
  String? roomId,
  String eventType = EventTypes.encrypted,
  Map? event,
}) {
  return (Store<AppState> store) async {
    try {
      // Pull out event data
      final Map content = event!['content'];
      final identityKey = content['sender_key'];

      // return already decrypted events
      if (content['ciphertext'] == null) {
        return event;
      }

      // Load and deserialize session
      final olm.InboundGroupSession messageSession = await store.dispatch(
        loadMessageSessionInbound(
          roomId: roomId,
          identityKey: identityKey,
        ),
      );

      // Decrypt the payload with the session
      final payloadDecrypted = messageSession.decrypt(content['ciphertext']);
      final payloadScrubbed = payloadDecrypted.plaintext
          .replaceAll(RegExp(r'\n', multiLine: true), '\\n')
          .replaceAll(RegExp(r'\t', multiLine: true), '\\t');

      // Return the content to be sent or processed
      event['content'] = json.decode(payloadScrubbed)['content'];

      await store.dispatch(saveMessageSessionInbound(
        roomId: roomId,
        identityKey: identityKey,
        session: messageSession,
        messageIndex: payloadDecrypted.message_index,
      ));

      return event;
    } catch (error) {
      debugPrint('[decryptMessageEvent] $error');
      return event;
    }
  };
}

/**
 * Encrypt key sharing event content with loaded outbound session for a device
 * 
 * NOTE: Utilizes available one time keys pre-fetched 
 * and claimed by the current user
 * 
 * https://matrix.org/docs/spec/client_server/latest#m-room-encrypted
 */
ThunkAction<AppState> encryptKeyContent({
  String? roomId,
  String? recipient,
  DeviceKey? recipientKeys, // recipient
  String eventType = EventTypes.roomKey,
  Map? content,
}) {
  return (Store<AppState> store) async {
    // pull current user identity keys out of olm account
    final userCurrent = store.state.authStore.user;
    final userOlmAccount = store.state.cryptoStore.olmAccount!;
    final userIdentityKeys = await json.decode(userOlmAccount.identity_keys());
    final userFingerprintKey = userIdentityKeys[Algorithms.ed25519];

    // pull recipient key data and id
    final fingerprintKeyId =
        Keys.fingerprint(deviceId: recipientKeys!.deviceId);
    final identityKeyId = Keys.identity(deviceId: recipientKeys.deviceId);
    final fingerprintKey = recipientKeys.keys![fingerprintKeyId]; // recipient
    final identityKey = recipientKeys.keys![identityKeyId]!; // recipient

    // create payload for olm key sharing per spec
    final payload = {
      'sender': userCurrent.userId,
      'sender_device': userCurrent.deviceId,
      'recipient': recipient,
      "recipient_keys": {
        Algorithms.ed25519: fingerprintKey,
      },
      "keys": {
        Algorithms.ed25519: userFingerprintKey,
      },
      'type': eventType,
      'content': content,
    };

    // all olm sessions should already be created
    // before sending a room key event to devices
    // load and deserialize session
    final olm.Session outboundKeySession = await store.dispatch(
      loadKeySessionOutbound(identityKey: identityKey),
    );

    // canoncially encode the json for encryption
    // TODO: CONFIRM WORKS WITHOUT CANONICAL JSON
    final payloadEncoded = json.encode(payload);
    // utf8.decode(payloadEncoded);
    final payloadSerialized = payloadEncoded;
    final payloadEncrypted = outboundKeySession.encrypt(payloadSerialized);

    // save the outbound session after processing content
    await store.dispatch(saveKeySessionOutbound(
      identityKey: identityKey,
      session: outboundKeySession.pickle(identityKey),
    ));

    // return the content to be sent or processed
    if (payloadEncrypted.type == 0) {
      return {
        'algorithm': Algorithms.olmv1,
        'sender_key': userIdentityKeys[Algorithms.curve25591],
        'ciphertext': {
          // receiver identity key
          identityKey: {
            'body': payloadEncrypted.body,
            'type': payloadEncrypted.type,
          }
        },
      };
    }

    return {
      'algorithm': Algorithms.olmv1,
      'sender_key': userIdentityKeys[Algorithms.curve25591],
      'ciphertext': payloadEncrypted.body,
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
ThunkAction<AppState> decryptKeyEvent({Map event = const {}}) {
  return (Store<AppState> store) async {
    // Get current user device identity key
    final deviceId = store.state.authStore.user.deviceId;
    final deviceKeysOwned = store.state.cryptoStore.deviceKeysOwned;
    final deviceKey = deviceKeysOwned[deviceId!]!;
    final deviceKeyId = '${Algorithms.curve25591}:$deviceId';
    final identityKeyOwned = deviceKey.keys![deviceKeyId];

    // Extract the payload meant for this device by identity
    final Map content = event['content'];
    final identityKeySender = content['sender_key'];
    final ciphertextContent = content['ciphertext'][identityKeyOwned];

    // Load and deserialize or create session
    final olm.Session keySession = await store.dispatch(
      loadKeySessionInbound(
        identityKey: identityKeySender,
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
 * 
 * The room_id, together with the sender_key of the m.room_key_ event before it was decrypted, and the session_id, uniquely identify a Megolm session
 * 
 * event = const {
    "content": {
      "algorithm": "m.megolm.v1.aes-sha2",
      "room_id": "!OXolesDwApoFSnipLA:matrix.org",
      "session_id": "MFgUVsIJtzKrl1tJdLC+yipG/uTIF5sBXd8NvvLjfQ4",
      "session_key":  "<session_key_data>" 
    },
    "room_id": "!OXolesDwApoFSnipLA:matrix.org",
    "type": "m.room_key"
  },
}
 */
ThunkAction<AppState> saveSessionKey({
  Map? event,
  String? identityKey,
}) {
  return (Store<AppState> store) async {
    // Extract the payload meant for this device by identity
    final Map content = event!['content'];
    final String? roomId = content['room_id'];
    final String? sessionKey = content['session_key'];

    // Load and deserialize or create session
    await store.dispatch(
      createMessageSessionInbound(
        roomId: roomId,
        identityKey: identityKey,
        sessionKey: sessionKey,
      ),
    );
  };
}

ThunkAction<AppState> syncDevice(Map toDeviceRaw) {
  return (Store<AppState> store) async {
    try {
      // Extract the new events
      final List<dynamic> events = toDeviceRaw['events'];
      printDebug('[syncDevice]');
      printJson(toDeviceRaw);

      // Parse and decrypt necessary events
      await Future.wait(events.map((event) async {
        final eventType = event['type'];
        final identityKeySender = event['content']['sender_key'];

        printDebug('[syncDevice] ${eventType}');

        switch (eventType) {
          case EventTypes.encrypted:
            try {
              final eventDecrypted = await store.dispatch(
                decryptKeyEvent(event: event),
              );

              if (EventTypes.roomKey == eventDecrypted['type']) {
                // save decrepted user session key under roomId
                await store.dispatch(
                  saveSessionKey(
                    event: eventDecrypted,
                    identityKey: identityKeySender,
                  ),
                );

                try {
                  // redecrypt events in the room with new key
                  final roomId = eventDecrypted['content']['room_id'];
                  Map<String, dynamic> room = {roomId: {}};

                  return await store.dispatch(syncRooms(room));
                } catch (error) {
                  debugPrint('[syncRooms|error] $error');
                }
              }
            } catch (error) {
              debugPrint('[decryptKeyEvent|error] $error');
            }

            break;
          default:
            break;
        }
      }));
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        origin: 'syncDevice',
      ));
    }
  };
}

// TODO: refactor sync device and/or use this one?
ThunkAction<AppState> syncDeviceNew(Map dataToDevice) {
  return (Store<AppState> store) async {
    try {
      // Extract the new events
      final List<dynamic> events = dataToDevice['events'];

      // Parse and decrypt necessary events
      for (final event in events) {
        final eventType = event['type'];
        final identityKeySender = event['content']['sender_key'];

        switch (eventType) {
          case EventTypes.encrypted:
            final eventDecrypted = await store.dispatch(
              decryptKeyEvent(event: event),
            );

            if (EventTypes.roomKey == eventDecrypted['type']) {
              await store.dispatch(
                saveSessionKey(
                  event: eventDecrypted,
                  identityKey: identityKeySender,
                ),
              );
            }
            break;
          default:
            break;
        }
      }
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        origin: 'syncDevice',
      ));
    }
  };
}
