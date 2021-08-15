import 'dart:convert';

import 'package:canonical_json/canonical_json.dart';
import 'package:flutter/material.dart';

import 'package:olm/olm.dart' as olm;
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/crypto/keys/actions.dart';
import 'package:syphon/store/crypto/model.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/room/model.dart';

/// Encrypt event content with loaded outbound session for room
///
/// https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#sending-an-encrypted-message-event
ThunkAction<AppState> encryptMessageContent({
  required String roomId,
  Map? content,
  String eventType = EventTypes.message,
}) {
  return (Store<AppState> store) async {
    // Load and deserialize session
    final olm.OutboundGroupSession outboundMessageSession = await store.dispatch(
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
      session: outboundMessageSession.pickle(roomId),
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

ThunkAction<AppState> decryptMessages(
  Room room,
  List<Message> messages,
) =>
    (Store<AppState> store) async {
      try {
        final roomId = room.id;
        final verified = store.state.authStore.verified;
        final decryptedAll = <Message>[];

        bool sentKeyRequest = false;

        // map through each event and decrypt if possible
        await Future.forEach(messages, (Message message) async {
          if (message.type != EventTypes.encrypted) {
            return;
          }

          try {
            final decryptedMessage = await store.dispatch(
              decryptMessage(roomId: roomId, message: message),
            );

            decryptedAll.add(decryptedMessage);
          } catch (error) {
            debugPrint('[decryptMessage] $error');

            if (!sentKeyRequest && verified) {
              sentKeyRequest = true;
              debugPrint('[decryptMessage] SENDING KEY REQUEST');
              store.dispatch(sendKeyRequest(
                event: message,
                roomId: room.id,
              ));
            }
          }
        });

        return decryptedAll;
      } catch (error) {
        printDebug(
          '[decryptMessage(s)] ${room.name ?? 'Unknown Room'} ${error.toString()}',
        );
      } finally {
        store.dispatch(UpdateRoom(id: room.id, syncing: false));
      }
    };

///
/// Decrypt Message
///
/// Decrypt Encrypted Message event content and return
/// a newly parsed decrypted, and seemingly unencrypted, Message
///
ThunkAction<AppState> decryptMessage({
  required String roomId,
  required Message message,
  String eventType = EventTypes.encrypted,
}) {
  return (Store<AppState> store) async {
    // Pull out event data
    final ciphertext = message.ciphertext;
    final identityKey = message.senderKey;
    final roomMessageIndexs = store.state.cryptoStore.messageSessionIndex[roomId];

    // return already decrypted events
    if (ciphertext == null || identityKey == null) {
      return message;
    }

    final identityMessageIndex = roomMessageIndexs?[identityKey] ?? 0;

    // Load and deserialize session
    final olm.InboundGroupSession messageSession = await store.dispatch(
      loadMessageSessionInbound(
        roomId: roomId,
        identityKey: identityKey,
      ),
    );

    // Decrypt the payload with the session
    final payloadDecrypted = messageSession.decrypt(ciphertext);
    final payloadScrubbed = payloadDecrypted.plaintext
        .replaceAll(RegExp(r'\n', multiLine: true), '\\n')
        .replaceAll(RegExp(r'\t', multiLine: true), '\\t');

    final messageIndexNew = payloadDecrypted.message_index;

    // protection against replay attacks
    if (messageIndexNew < identityMessageIndex) {
      throw '[decryptMessage] messageIndex invalid $messageIndexNew < $identityMessageIndex';
    }

    final decryptedJson = json.decode(payloadScrubbed);

    // TODO: TEST:
    printJson(decryptedJson);

    final decryptedMessage = Message.fromEvent(Event.fromMatrix(decryptedJson));

    // combine all possible decrypted fields with encrypted version of message
    final combinedMessage = message.copyWith(
      body: decryptedMessage.body,
      msgtype: decryptedMessage.msgtype,
      typeAlt: decryptedMessage.type,
    );

    // TODO: TEST:
    printJson(combinedMessage.toJson());

    await store.dispatch(saveMessageSessionInbound(
      roomId: roomId,
      identityKey: identityKey,
      session: messageSession,
      messageIndex: messageIndexNew,
    ));

    return combinedMessage;
  };
}

///
/// Decrypt Events
///
/// Reattribute decrypted events to the timeline
///
/// TODO: REMOVE
@Deprecated(
  'All encrypted messages are now decrypted post sync in a temp thread '
  'Remove once recreatable decryption is stable',
)
ThunkAction<AppState> decryptEvents(Room room, Map<String, dynamic> json) {
  return (Store<AppState> store) async {
    try {
      final verified = store.state.cryptoStore.deviceKeyVerified;

      // First past to decrypt encrypted events
      final List<dynamic> timelineEvents = json['timeline']['events'];

      bool sentKeyRequest = false;

      // map through each event and decrypt if possible
      final decryptTimelineActions = timelineEvents.map((event) async {
        final eventType = event['type'];
        switch (eventType) {
          case EventTypes.encrypted:
            try {
              return await store.dispatch(
                decryptMessageJson(roomId: room.id, event: event),
              );
            } catch (error) {
              debugPrint('[decryptMessageEvent] $error');

              if (!sentKeyRequest && verified) {
                sentKeyRequest = true;
                debugPrint('[decryptMessageEvent] SENDING KEY REQUEST');
                store.dispatch(sendKeyRequest(
                  event: Message.fromEvent(Event.fromMatrix(event)),
                  roomId: room.id,
                ));
              }

              return event;
            }
          default:
            return event;
        }
      });

      // add the decrypted events back to the
      final decryptedTimelineEvents = await Future.wait(
        decryptTimelineActions,
      );

      return decryptedTimelineEvents;
    } catch (error) {
      debugPrint(
        '[decryptEvents] ${room.name ?? 'Unknown Room Name'} ${error.toString()}',
      );
    } finally {
      store.dispatch(UpdateRoom(id: room.id, syncing: false));
    }
  };
}

///
/// Decrypt Message Event
///
/// Decrypt Encrypted Message event content and return
/// a newly parsed decrypted, and seemingly unencrypted, Message
///
/// https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#sending-an-encrypted-message-event
///
@Deprecated('No longer used after decryption fixes branch release - version 0.1.11')
ThunkAction<AppState> decryptMessageJson({
  required String roomId,
  String eventType = EventTypes.encrypted,
  Map event = const {},
}) {
  return (Store<AppState> store) async {
    // Pull out event data
    final Map content = event['content'];
    final String identityKey = content['sender_key'];

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
  };
}

/// Encrypt key sharing event content with loaded outbound session for a device
///
/// NOTE: Utilizes available one time keys pre-fetched
/// and claimed by the current user
///
/// https://matrix.org/docs/spec/client_server/latest#m-room-encrypted
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
    final currentIdentityKeys = await json.decode(userOlmAccount.identity_keys());
    final currentFingerprint = currentIdentityKeys[Algorithms.ed25519];

    // pull recipient key data and id
    final fingerprintId = Keys.fingerprintId(deviceId: recipientKeys!.deviceId);
    final identityKeyId = Keys.identityKeyId(deviceId: recipientKeys.deviceId);

    final fingerprint = recipientKeys.keys![fingerprintId]; // recipient
    final identityKey = recipientKeys.keys![identityKeyId]!; // recipient

    // create payload for olm key sharing per spec
    final payload = {
      'sender': userCurrent.userId,
      'sender_device': userCurrent.deviceId,
      'recipient': recipient,
      'recipient_keys': {
        Algorithms.ed25519: fingerprint,
      },
      'keys': {
        Algorithms.ed25519: currentFingerprint,
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
    final payloadEncoded = canonicalJson.encode(payload);
    final payloadSerialized = utf8.decode(payloadEncoded);
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
        'sender_key': currentIdentityKeys[Algorithms.curve25591],
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
      'sender_key': currentIdentityKeys[Algorithms.curve25591],
      'ciphertext': payloadEncrypted.body,
    };
  };
}

/// Decrypting toDevice event content with loaded
/// key session (outbound | inbound) for that device
///
/// NOTE: Utilizes available one time keys pre-fetched
/// and claimed by the current user
///
/// https://matrix.org/docs/spec/client_server/latest#m-room-encrypted
ThunkAction<AppState> decryptKeyEvent({Map event = const {}}) {
  return (Store<AppState> store) async {
    // Get current user device identity key
    final deviceId = store.state.authStore.user.deviceId;
    final deviceKeysOwned = store.state.cryptoStore.deviceKeysOwned;

    final deviceKey = deviceKeysOwned[deviceId!]!;

    final identityKeyId = Keys.identityKeyId(deviceId: deviceId);
    final identityKey = deviceKey.keys![identityKeyId];

    // Extract the payload meant for this device by identity
    final Map content = event['content'];
    final identityKeySender = content['sender_key'];
    final ciphertextContent = content['ciphertext'][identityKey];

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

///
/// Saving a message session key from a m.room_key event
///
/// https://matrix.org/docs/spec/client_server/latest#m-room-encrypted
///
/// The room_id, together with the sender_key of the m.room_key_ event before it was decrypted,
/// and the session_id, uniquely identify a Megolm session
///
/// event = const {
///     "content": {
///       "algorithm": "m.megolm.v1.aes-sha2",
///       "room_id": "!OXolesDwApoFSnipLA:matrix.org",
///       "session_id": "MFgUVsIJtzKrl1tJdLC+yipG/uTIF5sBXd8NvvLjfQ4",
///       "session_key":  "<session_key_data>"
///     },
///     "room_id": "!OXolesDwApoFSnipLA:matrix.org",
///     "type": "m.room_key"
///   },
/// }
ThunkAction<AppState> saveSessionKey({
  Map? event,
  String? identityKey,
}) {
  return (Store<AppState> store) async {
    // Extract the payload meant for this device by identity
    final Map content = event!['content'];
    final String? roomId = content['room_id'];
    final String? sessionKey = content['session_key'];

    if (roomId == null || sessionKey == null || identityKey == null) {
      throw '[saveSessionKey] Failed to create message session $roomId, $sessionKey, $identityKey';
    }

    // Load and deserialize or create session
    await store.dispatch(createMessageSessionInbound(
      roomId: roomId,
      identityKey: identityKey,
      sessionKey: sessionKey,
    ));
  };
}

ThunkAction<AppState> syncDevice(Map toDeviceRaw) {
  return (Store<AppState> store) async {
    try {
      // Extract the new events
      final List<dynamic> events = toDeviceRaw['events'];

      // Parse and decrypt necessary events
      await Future.wait(events.map((event) async {
        final eventType = event['type'];
        final identityKeySender = event['content']['sender_key'];

        switch (eventType) {
          case EventTypes.encrypted:
            try {
              // printJson(toDeviceRaw); // TODO: test olm recovery

              final eventDecrypted = await store.dispatch(
                decryptKeyEvent(event: event),
              );

              if (EventTypes.roomKey == eventDecrypted['type']) {
                // save decrepted user session key under roomId
                await store.dispatch(saveSessionKey(
                  event: eventDecrypted,
                  identityKey: identityKeySender,
                ));

                try {
                  // redecrypt events in the room with new key
                  final roomId = eventDecrypted['content']['room_id'];

                  final room = store.state.roomStore.rooms[roomId];
                  final messages = store.state.eventStore.messages;
                  final messagesDecrypted = store.state.eventStore.messagesDecrypted;

                  if (!messages.containsKey(roomId) || room == null) {
                    return;
                  }

                  // grab room messages and attempt decrypting ones that have not been
                  final roomMessages = messages[roomId] ?? [];
                  final roomDecrypted = messagesDecrypted[roomId] ?? [];

                  final undecrypted = roomMessages.where((msg) => roomDecrypted.contains(msg)).toList();

                  final decrypted = await store.dispatch(decryptMessages(
                    room,
                    undecrypted,
                  )) as List<Message>;

                  return await store.dispatch(addMessagesDecrypted(
                    room: room,
                    messages: decrypted,
                  ));
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
