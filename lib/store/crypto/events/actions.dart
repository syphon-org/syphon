import 'dart:convert';

import 'package:canonical_json/canonical_json.dart';
import 'package:flutter/material.dart';
import 'package:olm/olm.dart' as olm;
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
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
import 'package:syphon/store/media/actions.dart';
import 'package:syphon/store/media/encryption.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/room/model.dart';

///
/// Encrypt event content with loaded outbound session for room
///
/// https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#sending-an-encrypted-message-event
///
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

///
/// Decrypt Message(s)
///
/// Decrypt a series of messages found in the normal
/// events cache
///
ThunkAction<AppState> backfillDecryptMessages(
  String roomId,
) {
  return (Store<AppState> store) async {
    try {
      final rooms = store.state.roomStore.rooms;

      if (!rooms.containsKey(roomId)) {
        throw 'No room found for room ID $roomId';
      }

      // redecrypt events in the room with new key
      final messages = store.state.eventStore.messages;

      if (!messages.containsKey(roomId)) {
        throw 'No messages found to decrypt for this room';
      }

      // grab room messages and attempt decrypting ones that have not been
      final room = rooms[roomId]!;
      final messagesDecrypted = store.state.eventStore.messagesDecrypted;
      final roomMessages = messages[roomId] ?? [];
      final roomDecrypted = messagesDecrypted[roomId] ?? [];

      final undecrypted = roomMessages.where((msg) => roomDecrypted.contains(msg)).toList();

      final decrypted = await store.dispatch(decryptMessages(
        room,
        undecrypted,
      )) as List<Message>;

      return await store.dispatch(addMessagesDecrypted(
        roomId: room.id,
        messages: decrypted,
      ));
    } catch (error) {
      printError('[syncDevice] error $error');
    }
  };
}

///
/// Decrypt Message(s)
///
/// Decrypt a series of messages found in the normal
/// events cache
///
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
            printError('[decryptMessage] $error');

            if (!sentKeyRequest && verified) {
              sentKeyRequest = true;
              store.dispatch(sendKeyRequest(
                event: message,
                roomId: room.id,
              ));
            }
          }
        });

        return decryptedAll;
      } catch (error) {
        printError(
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
  bool forceDecryption = true,
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

    final identityMessageIndex = roomMessageIndexs?[identityKey] ?? -1;

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
    if ((messageIndexNew <= identityMessageIndex && identityMessageIndex != 0) &&
        !forceDecryption) {
      throw '[decryptMessage] messageIndex invalid $messageIndexNew <= $identityMessageIndex';
    }

    final decryptedJson = json.decode(payloadScrubbed);

    final decryptedMessage = Message.fromEvent(
      Event.fromMatrix(decryptedJson),
    );

    // combine all possible decrypted fields with encrypted version of message
    var combinedMessage = message.copyWith(
      url: decryptedMessage.url,
      body: decryptedMessage.body,
      format: decryptedMessage.format,
      formattedBody: decryptedMessage.formattedBody,
      msgtype: decryptedMessage.msgtype,
      typeDecrypted: decryptedMessage.type,
      file: decryptedMessage.file,
      info: decryptedMessage.info,
    );

    // update media store with iv, keys for decrypting said media
    if (MessageType.image.value == decryptedMessage.msgtype) {
      final mxcUri = combinedMessage.file?['url']; // encrypted image only
      final iv = combinedMessage.file?['iv'];
      final key = combinedMessage.file?['key']['k'];
      final shasum = combinedMessage.file?['hashes']['sha256'];

      store.dispatch(UpdateMediaCache(
        mxcUri: mxcUri,
        info: EncryptInfo(iv: iv, key: key, shasum: shasum),
      ));

      // unfortunately, decrypted images have urls under the file property
      combinedMessage = combinedMessage.copyWith(
        url: mxcUri,
      );
    }

    await store.dispatch(saveMessageSessionInbound(
      roomId: roomId,
      identityKey: identityKey,
      session: messageSession,
      messageIndex: messageIndexNew,
    ));

    return combinedMessage;
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
  Map? content,
  DeviceKey? recipientKey,
  String eventType = EventTypes.roomKey,
}) {
  return (Store<AppState> store) async {
    // pull current user identity keys out of olm account
    final userCurrent = store.state.authStore.user;
    final deviceId = userCurrent.deviceId!;
    final userOlmAccount = store.state.cryptoStore.olmAccount!;
    final currentIdentityKeys = await json.decode(userOlmAccount.identity_keys());
    final currentFingerprint = currentIdentityKeys[Algorithms.ed25519];

    // pull recipient key data and id
    final fingerprintId = Keys.fingerprintId(deviceId: recipientKey!.deviceId);
    final identityKeyId = Keys.identityKeyId(deviceId: recipientKey.deviceId);

    final fingerprint = recipientKey.keys![fingerprintId]; // recipient
    final identityKey = recipientKey.keys![identityKeyId]!; // recipient

    // create payload for olm key sharing per spec
    final payload = {
      'sender': userCurrent.userId,
      'sender_device': userCurrent.deviceId,
      'recipient': recipientKey.userId,
      'recipient_keys': {
        Algorithms.ed25519: fingerprint,
      },
      'keys': {
        Algorithms.ed25519: currentFingerprint,
      },
      'type': eventType,
      'content': content,
    };

    // all olm sessions should already be created or received
    // before sending a room key event to devices
    // load and deserialize session
    final olm.Session keySession = await store.dispatch(
      loadKeySessionOutbound(identityKey: identityKey),
    );

    // canoncially encode the json for encryption
    final payloadEncoded = canonicalJson.encode(payload);
    final payloadSerialized = utf8.decode(payloadEncoded);
    final payloadEncrypted = keySession.encrypt(payloadSerialized);

    // save the outbound session after processing content
    store.dispatch(saveKeySession(
      identityKey: identityKey,
      sessionId: keySession.session_id(),
      session: keySession.pickle(deviceId),
    ));

    // return the content to be sent or processed
    return {
      'algorithm': Algorithms.olmv1,
      'sender_key': currentIdentityKeys[Algorithms.curve25591],
      'ciphertext': {
        // recipient identity key
        identityKey: {
          'body': payloadEncrypted.body,
          'type': payloadEncrypted.type,
        }
      },
    };
  };
}

///
/// Decrypting Key Event
///
/// Decrypt to_device event content with loaded
/// key session (outbound | inbound) for that device
///
/// NOTE: Utilizes available one time keys pre-fetched
/// and claimed by the current user
///
/// https://matrix.org/docs/spec/client_server/latest#m-room-encrypted
///
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
    final Map ciphertextContent = content['ciphertext'][identityKey];
    final int type = ciphertextContent['type'] as int;
    final String body = ciphertextContent['body'] as String;
    final identityKeySender = content['sender_key'];

    // Load and deserialize or create session
    final olm.Session keySession = await store.dispatch(
      loadKeySessionInbound(
        identityKey: identityKeySender,
        type: type,
        body: body,
      ),
    );

    // Decrypt the payload with the session for device identity
    final decryptedPayload = keySession.decrypt(type, body);

    await store.dispatch(saveKeySession(
      identityKey: identityKeySender,
      sessionId: keySession.session_id(),
      session: keySession.pickle(deviceId),
    ));

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

      // parse and decrypt each to_device encrypted event
      // can be run in parrallel unlike message decryption
      await Future.wait(events.map((event) async {
        final eventType = event['type'];
        final identityKeySender = event['content']['sender_key'];

        switch (eventType) {
          case EventTypes.encrypted:
            try {
              final Map eventDecrypted = await store.dispatch(
                decryptKeyEvent(event: event),
              );

              final eventType = eventDecrypted['type'] as String;

              if (EventTypes.roomKey == eventType) {
                final roomId = eventDecrypted['content']['room_id'] as String;

                // save decrepted user session key under roomId
                await store.dispatch(saveSessionKey(
                  event: eventDecrypted,
                  identityKey: identityKeySender,
                ));

                backfillDecryptMessages(roomId);
              }
            } catch (error) {
              printError('[decryptKeyEvent] [ERROR] $error');
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
