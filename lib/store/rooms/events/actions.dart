import 'dart:convert';
import 'dart:math';

import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/crypto/events/actions.dart';
import 'package:syphon/store/crypto/keys/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/events/model.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

final protocol = DotEnv().env['PROTOCOL'];

/**
 * 
  class MessageTypes {
    static const TEXT = 'm.text';
    static const EMOTE = 'm.emote';
    static const NOTICE = 'm.notice';
    static const IMAGE = 'm.text';
    static const FILE = 'm.file';
    static const AUDIO = 'm.text';
    static const LOCATION = 'm.location';
    static const VIDEO = 'm.video';
  }
 */

/**
 * Load Message Events
 * 
 * Pulls next message events from cold storage 
 */
ThunkAction<AppState> loadMessageEvents({Room room}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(UpdateRoom(id: room.id, syncing: true));
    } catch (error) {
      print('[fetchMessageEvents] error $error');
    } finally {
      store.dispatch(UpdateRoom(id: room.id, syncing: false));
    }
  };
}

/**
 * Fetch Message Events
 * 
 * https://matrix.org/docs/spec/client_server/latest#syncing
 * https://matrix.org/docs/spec/client_server/latest#get-matrix-client-r0-rooms-roomid-messages
 * 
 * Pulls next message events remote from homeserver
 */
ThunkAction<AppState> fetchMessageEvents({
  Room room,
  String endHash,
  String startHash,
  int limit = 20, // TODO: bump to 30
}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(UpdateRoom(id: room.id, syncing: true));

      // last since called on /sync
      final lastSince = store.state.syncStore.lastSince;

      final Map messagesJson = await MatrixApi.fetchMessageEvents(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        to: endHash,
        from: startHash ?? lastSince,
        roomId: room.id,
        limit: limit,
      );

      // The token the pagination ends at. If dir=b this token should be used again to request even earlier events.
      final String end = messagesJson['end'];
      // The token the pagination starts from. If dir=b this will be the token supplied in from.
      final String start = messagesJson['start'];
      final List<dynamic> messages = messagesJson['chunk'] ?? [];

      // print('[fetchMessageEvents] ${room.name} end $end');
      // print('[fetchMessageEvents] ${room.name} start $start');
      // messages.forEach((message) {
      //   print(
      //     '[fetchMessageEvents]  ${message['sender']} ${message}',
      //   );
      // });

      // If there's a gap in messages fetched, run a sync again
      // which will fetch the next batch with the same endHash
      // the following is probably not needed due to the
      // inequality check for prevHash and endHash in syncRooms
      var nextPrevBatch;
      if (end != start && end != endHash) {
        nextPrevBatch = end;
      }

      // reuse the logic for syncing
      store.dispatch(syncRooms(
        {
          '${room.id}': {
            'timeline': {
              'events': messages,
              'prev_batch': nextPrevBatch,
            }
          },
        },
      ));
    } catch (error) {
      print('[fetchMessageEvents] error $error');
    } finally {
      store.dispatch(UpdateRoom(id: room.id, syncing: false));
    }
  };
}

/**
 * 
 * TODO: not sure if we need this, but just
 * trying to finish E2EE first
 * 
 * state events can only be 
 * done from full state /sync data
 */
ThunkAction<AppState> fetchStateEvents({Room room}) {
  return (Store<AppState> store) async {
    try {
      final stateEvents = await MatrixApi.fetchStateEvents(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        roomId: room.id,
      );

      if (!(stateEvents is List) && stateEvents['errcode'] != null) {
        throw stateEvents['error'];
      }

      store.dispatch(syncRooms({
        '${room.id}': {
          'state': {
            'events': stateEvents,
          },
        },
      }));
    } catch (error) {
      print('[fetchRooms] ${room.id} $error');
    } finally {
      store.dispatch(UpdateRoom(id: room.id, syncing: false));
    }
  };
}

/**
 * https://matrix-client.matrix.org/_matrix/client/r0/rooms/!ajJxpUAIJjYYTzvsHo%3Amatrix.org/read_markers
 * {"m.fully_read":"$15870915721387891MHmpg:matrix.org","m.read":"$15870915721387891MHmpg:matrix.org","m.hidden":false}
 * TODO: 
 */
ThunkAction<AppState> readMessages({
  Room room,
  Message message,
  bool readAll = true,
}) {
  return (Store<AppState> store) async {
    try {} catch (error) {
      print('[readMessage] failed to send: $error');
    }
  };
}

ThunkAction<AppState> saveDraft({
  final body,
  String type = 'm.text',
  Room room,
}) {
  return (Store<AppState> store) async {
    store.dispatch(UpdateRoom(
      id: room.id,
      draft: Message(
        roomId: room.id,
        type: type,
        body: body,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    ));
  };
}

ThunkAction<AppState> sendTyping({
  String roomId,
  bool typing = false,
}) {
  return (Store<AppState> store) async {
    try {
      // Skip if typing indicators are disabled
      if (!store.state.settingsStore.typingIndicators) {
        print('[sendTyping] typing indicators disabled');
        return;
      }

      print('[sendTyping] pushing $typing');

      final data = await MatrixApi.sendTyping(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: roomId,
        userId: store.state.authStore.user.userId,
        typing: typing,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }
    } catch (error) {
      print('[toggleTyping] $error');
    }
  };
}

/**
 * Send Session Encryption Keys
 * 
 * Specifically for sending encrypted keys using olm
 * for later use with encrypted messages using megolm
 * sent directly to devices within the room
 * 
 * https://matrix.org/docs/spec/client_server/latest#id454
 * https://matrix.org/docs/spec/client_server/latest#id461
 */
/**
 */
ThunkAction<AppState> sendSessionKeys({
  Room room,
}) {
  return (Store<AppState> store) async {
    try {
      print('[sendSessionKeys] start');

      // if you're incredibly unlucky, and fast, you could have a problem here
      final String trxId = DateTime.now().millisecond.toString();

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
      final oneTimeKeys = store.state.cryptoStore.oneTimeKeysClaimed;
      await store.dispatch(claimOneTimeKeys(room: room));

      // For each one time key claimed
      // send a m.room_key event directly to each device

      final List<OneTimeKey> devicesOneTimeKeys = List.from(oneTimeKeys.values);

      print(
        '[sendSessionKeys] ${devicesOneTimeKeys.length}',
      );

      final sendToDeviceRequests = devicesOneTimeKeys.map((oneTimeKey) async {
        try {
          final deviceKey = store.state.cryptoStore
              .deviceKeys[oneTimeKey.userId][oneTimeKey.deviceId];

          // find the identityKey for the device
          final keyId = '${Algorithms.curve25591}:${deviceKey.deviceId}';
          final identityKey = deviceKey.keys[keyId];

          // Poorly decided to save key sessions by deviceId at first but then
          // realised that you may have the same identityKey for diff
          // devices and you also don't have the device id in the
          // toDevice event payload -__-, convert back to identity key
          final roomKeyEventContentEncrypted = await store.dispatch(
            encryptKeyContent(
              roomId: room.id,
              identityKey: identityKey, // TODO identityKey after testing
              eventType: EventTypes.roomKey,
              content: roomKeyEventContent,
            ),
          );

          print(
            '[sendSessionKeys] $roomKeyEventContentEncrypted',
          );

          final response = await MatrixApi.sendEventToDevice(
            protocol: protocol,
            accessToken: store.state.authStore.user.accessToken,
            homeserver: store.state.authStore.user.homeserver,
            userId: deviceKey.userId,
            deviceId: deviceKey.deviceId,
            eventType: EventTypes.encrypted,
            content: roomKeyEventContentEncrypted,
            trxId: trxId,
          );

          if (response['errcode'] != null) {
            throw response['error'];
          }

          print(
            '[sendSessionKeys] ${oneTimeKey.deviceId} sent and completed',
          );
        } catch (error) {
          print(
            '[sendSessionKeys] ${oneTimeKey.deviceId} $error',
          );
        }
      });

      // await all sendToDevice room key events to be sent to users
      await Future.wait(sendToDeviceRequests);
    } catch (error) {
      store.dispatch(
        addAlert(type: 'warning', message: error.message),
      );
    }
  };
}

/**
 * Send Encrypted Messages
 * 
 * Specifically for sending encrypted messages using megolm
 */
ThunkAction<AppState> sendMessageEncrypted({
  Room room,
  final body,
  String type = MessageTypes.TEXT,
}) {
  return (Store<AppState> store) async {
    try {
      // if you're incredibly unlucky, and fast, you could have a problem here
      final String trxId = DateTime.now().millisecond.toString();

      print('[sendMessageEncrypted] $trxId');

      // send the session keys if an inbound session does not exist
      final messageSession =
          store.state.cryptoStore.inboundMessageSessions[room.id];

      if (messageSession == null) {
        await store.dispatch(
          sendSessionKeys(room: room),
        );
      }

      final messageEvent = {
        'body': body,
        'type': type,
      };

      final encryptedEvent = await store.dispatch(
        encryptMessageContent(
          roomId: room.id,
          eventType: EventTypes.message,
          content: messageEvent,
        ),
      );

      print('[sendMessageEncrypted $encryptedEvent');

      // TODO: encrypt and send actual message content
      final data = await MatrixApi.sendMessageEncrypted(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        trxId: trxId,
        roomId: room.id,
        senderKey: encryptedEvent['sender_key'],
        ciphertext: encryptedEvent['ciphertext'],
        sessionId: encryptedEvent['session_id'],
        deviceId: store.state.authStore.user.deviceId,
      );

      print('[sendMessageEncrypted completed $data');

      if (data['errcode'] != null) {
        throw data['error'];
      }
    } catch (error) {
      store.dispatch(
        addAlert(
          type: 'warning',
          message: error.message,
          origin: 'sendMessageEncrypted',
        ),
      );
    }
  };
}

/**
 * Send Room Event (Send Message)
 */
ThunkAction<AppState> sendMessage({
  Room room,
  final body,
  String type = MessageTypes.TEXT,
}) {
  return (Store<AppState> store) async {
    store.dispatch(SetSending(room: room, sending: true));

    // if you're incredibly unlucky, and fast, you could have a problem here
    final String tempId = Random.secure().nextInt(1 << 32).toString();

    try {
      print('[sendMessage] ${type} ${body}');

      // Save unsent message to outbox
      store.dispatch(SaveOutboxMessage(
        id: room.id,
        pendingMessage: Message(
          id: tempId.toString(),
          body: body,
          type: type,
          sender: store.state.authStore.user.userId,
          roomId: room.id,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          pending: true,
          syncing: true,
        ),
      ));

      final message = {
        'body': body,
        'type': type,
      };

      final data = await MatrixApi.sendMessage(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        trxId: DateTime.now().millisecond.toString(),
        roomId: room.id,
        message: message,
      );

      if (data['errcode'] != null) {
        store.dispatch(SaveOutboxMessage(
          id: room.id,
          tempId: tempId.toString(),
          pendingMessage: Message(
            id: tempId.toString(),
            body: body,
            type: type,
            sender: store.state.authStore.user.userId,
            roomId: room.id,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            pending: false,
            syncing: false,
            failed: true,
          ),
        ));

        throw data['error'];
      }

      // Update sent message with event id but needs to be
      // synced to remove from outbox
      store.dispatch(SaveOutboxMessage(
        id: room.id,
        tempId: tempId.toString(),
        pendingMessage: Message(
          id: data['event_id'],
          body: body,
          type: type,
          sender: store.state.authStore.user.userId,
          roomId: room.id,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          syncing: true,
        ),
      ));

      return true;
    } catch (error) {
      print('[sendMessage] failed to send: $error');
      return false;
    } finally {
      store.dispatch(SetSending(room: room, sending: false));
    }
  };
}

/**
 * Delete Room Event (For Outbox, Local, and Remote)
 */

ThunkAction<AppState> deleteMessage({
  Message message,
}) {
  return (Store<AppState> store) async {
    try {
      if (message.pending || message.failed) {
        print("Deleting Message");
        store.dispatch(DeleteOutboxMessage(message: message));
        return;
      }
    } catch (error) {
      print('[deleteMessage] failed to delete $error');
    }
  };
}
