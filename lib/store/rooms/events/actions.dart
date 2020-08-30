// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

// Project imports:
import 'package:syphon/global/algos.dart';
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

final protocol = DotEnv().env['PROTOCOL'];

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
      debugPrint('[fetchMessageEvents] $error');
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
  int limit = 20,
}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(UpdateRoom(id: room.id, syncing: true));

      final messagesJson = await compute(MatrixApi.fetchMessageEventsMapped, {
        "protocol": protocol,
        "homeserver": store.state.authStore.user.homeserver,
        "accessToken": store.state.authStore.user.accessToken,
        "roomId": room.id,
        "to": endHash,
        "from": startHash,
        "limit": limit,
      });

      // The token the pagination ends at. If dir=b this token should be used again to request even earlier events.
      final String end = messagesJson['end'];
      // The token the pagination starts from. If dir=b this will be the token supplied in from.
      final String start = messagesJson['start'];
      // The messages themselves
      final List<dynamic> messages = messagesJson['chunk'] ?? [];

      // If there's a gap in messages fetched, run a sync again
      // which will fetch the next batch with the same endHash
      // the following is probably not needed due to the
      // inequality check for prevHash and endHash in syncRooms
      // NOTE: nextPrevBatch by end hash is just to load more
      // should be refactored
      var nextPrevBatch;
      if ((end != start && end != endHash)) {
        nextPrevBatch = end;
      }

      // reuse the logic for syncing
      await store.dispatch(
        syncRooms({
          '${room.id}': {
            'timeline': {
              'events': messages,
              'end_batch': end,
              'prev_batch': nextPrevBatch,
            }
          },
        }),
      );
    } catch (error) {
      debugPrint('[fetchMessageEvents] $error');
    } finally {
      store.dispatch(UpdateRoom(id: room.id, syncing: false));
    }
  };
}

/**
 *  
 * Fetch State Events
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

      await store.dispatch(syncRooms({
        '${room.id}': {
          'state': {
            'events': stateEvents,
          },
        },
      }));
    } catch (error) {
      debugPrint('[fetchStateEvents] $error');
    } finally {
      store.dispatch(UpdateRoom(id: room.id, syncing: false));
    }
  };
}

ThunkAction<AppState> clearDraft({Room room}) {
  return (Store<AppState> store) async {
    store.dispatch(UpdateRoom(
      id: room.id,
      draft: Message(
        roomId: room.id,
        body: null,
      ),
    ));
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

/**
 * 
 * Read Message Marker
 * 
 * Send Fully Read or just Read receipts bundled into 
 * one http call
 */
ThunkAction<AppState> sendReadReceipts({
  Room room,
  Message message,
  bool readAll = true,
}) {
  return (Store<AppState> store) async {
    try {
      // Skip if typing indicators are disabled
      if (!store.state.settingsStore.readReceipts) {
        return debugPrint('[sendReadReceipts] read receipts disabled');
      }

      final data = await MatrixApi.sendReadReceipts(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room.id,
        messageId: message.id,
        readAll: readAll,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      debugPrint('[sendReadReceipts] sent ${message.id} $data');
    } catch (error) {
      debugPrint('[sendReadReceipts] failed $error');
    }
  };
}
/**
 * 
 * Read Message Marker
 * 
 * Send Fully Read or just Read receipts bundled into 
 * one http call
 */

ThunkAction<AppState> sendTyping({
  String roomId,
  bool typing = false,
}) {
  return (Store<AppState> store) async {
    try {
      // Skip if typing indicators are disabled
      if (!store.state.settingsStore.typingIndicators) {
        debugPrint('[sendTyping] typing indicators disabled');
        return;
      }

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
      debugPrint('[sendTyping] $error');
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
      // send the key session - if one hasn't been sent
      // or created - to every user within the room
      await store.dispatch(updateKeySessions(room: room));

      // Save unsent message to outbox
      final tempId = Random.secure().nextInt(1 << 32).toString();

      store.dispatch(SaveOutboxMessage(
        id: room.id,
        pendingMessage: Message(
          id: tempId,
          body: body,
          type: type,
          sender: store.state.authStore.user.userId,
          roomId: room.id,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          pending: true,
          syncing: true,
        ),
      ));

      final messageEvent = {
        'body': body,
        'type': type,
      };

      // Encrypt the message event
      final encryptedEvent = await store.dispatch(
        encryptMessageContent(
          roomId: room.id,
          eventType: EventTypes.message,
          content: messageEvent,
        ),
      );

      final data = await MatrixApi.sendMessageEncrypted(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        trxId: DateTime.now().millisecond.toString(),
        roomId: room.id,
        senderKey: encryptedEvent['sender_key'],
        ciphertext: encryptedEvent['ciphertext'],
        sessionId: encryptedEvent['session_id'],
        deviceId: store.state.authStore.user.deviceId,
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
    } catch (error) {
      store.dispatch(
        addAlert(
            error: error,
            message: error.toString(),
            origin: 'sendMessageEncrypted'),
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
      debugPrint('[sendMessage] $error');
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
        store.dispatch(DeleteOutboxMessage(message: message));
        return;
      }
    } catch (error) {
      debugPrint('[deleteMessage] $error');
    }
  };
}
