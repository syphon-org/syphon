// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Package imports:
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/algos.dart';

// Project imports:
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/crypto/events/actions.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/store/events/selectors.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/rooms/room/model.dart';

final protocol = DotEnv().env['PROTOCOL'];

ThunkAction<AppState> initRevisedMessages({
  Room room,
  Message message,
}) {
  return (Store<AppState> store) async {
    final roomMessages = store.state.eventStore.messages;
    final reactions = store.state.eventStore.reactions;
    final redactions = store.state.eventStore.redactions;

    await Future.wait(roomMessages.entries.map((entry) async {
      final roomId = entry.key;
      final allMessages = entry.value;

      final revisedMessages = await compute(reviseMessagesBackground, {
        'reactions': reactions,
        'redactions': redactions,
        'roomMessages': allMessages,
      });

      store.dispatch(setMessages(
        room: Room(id: roomId),
        messages: revisedMessages,
      ));
    }));
  };
}

/// Send Message
ThunkAction<AppState> sendMessage({
  Room room,
  Message message,
}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(UpdateRoom(id: room.id, sending: true));

      // if you're incredibly unlucky, and fast, you could have a problem here
      final tempId = Random.secure().nextInt(1 << 32).toString();
      final reply = store.state.roomStore.rooms[room.id].reply;

      // trim trailing whitespace
      message = message.copyWith(body: message.body.trimRight());

      // pending outbox message
      var pending = Message(
        id: tempId,
        body: message.body,
        type: message.type,
        content: {
          'body': message.body,
          'msgtype': message.type ?? MessageTypes.TEXT,
        },
        sender: store.state.authStore.user.userId,
        roomId: room.id,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        pending: true,
        syncing: true,
      );

      if (reply != null && reply.body != null) {
        pending = await store.dispatch(
          formatMessageReply(room, pending, reply),
        );
      }
      // Save unsent message to outbox
      store.dispatch(SaveOutboxMessage(
        id: room.id,
        pendingMessage: pending,
      ));

      final data = await MatrixApi.sendMessage(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        trxId: DateTime.now().millisecond.toString(),
        roomId: room.id,
        message: pending.content,
      );

      if (data['errcode'] != null) {
        store.dispatch(SaveOutboxMessage(
          id: room.id,
          tempId: tempId.toString(),
          pendingMessage: pending.copyWith(
            timestamp: DateTime.now().millisecondsSinceEpoch,
            pending: false,
            syncing: false,
            failed: true,
          ),
        ));

        throw data['error'];
      }

      // Update sent message with event id but needs
      // to be syncing to remove from outbox
      store.dispatch(SaveOutboxMessage(
        id: room.id,
        tempId: tempId.toString(),
        pendingMessage: pending.copyWith(
          id: data['event_id'],
          timestamp: DateTime.now().millisecondsSinceEpoch,
          syncing: true,
        ),
      ));

      return true;
    } catch (error) {
      store.dispatch(
        addAlert(
          error: error,
          message: error.toString(),
          origin: 'sendMessage',
        ),
      );
      return false;
    } finally {
      store.dispatch(UpdateRoom(id: room.id, sending: false, reply: Message()));
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
  Message message, // body and type only for now
}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(UpdateRoom(id: room.id, sending: true));

      // send the key session - if one hasn't been sent
      // or created - to every user within the room
      await store.dispatch(updateKeySessions(room: room));

      // Save unsent message to outbox
      final tempId = Random.secure().nextInt(1 << 32).toString();
      final reply = store.state.roomStore.rooms[room.id].reply;

      // trim trailing whitespace
      message = message.copyWith(body: message.body.trimRight());

      // pending outbox message
      var pending = Message(
        id: tempId.toString(),
        body: message.body,
        type: message.type,
        content: {
          'body': message.body,
          'msgtype': message.type ?? MessageTypes.TEXT,
        },
        sender: store.state.authStore.user.userId,
        roomId: room.id,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        pending: true,
        syncing: true,
      );

      var unencryptedData = {};

      if (reply != null && reply.body != null) {
        pending = await store.dispatch(
          formatMessageReply(room, pending, reply),
        );
        unencryptedData["m.relates_to"] = {
          "m.in_reply_to": {"event_id": "${reply.id}"}
        };
      }

      store.dispatch(SaveOutboxMessage(
        id: room.id,
        pendingMessage: pending,
      ));

      // Encrypt the message event
      final encryptedEvent = await store.dispatch(
        encryptMessageContent(
          roomId: room.id,
          eventType: EventTypes.message,
          content: pending.content,
        ),
      );

      final data = await MatrixApi.sendMessageEncrypted(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        unencryptedData: unencryptedData,
        accessToken: store.state.authStore.user.accessToken,
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
          pendingMessage: pending.copyWith(
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
        pendingMessage: pending.copyWith(
          id: data['event_id'],
          timestamp: DateTime.now().millisecondsSinceEpoch,
          syncing: true,
        ),
      ));
      return true;
    } catch (error) {
      store.dispatch(
        addAlert(
          error: error,
          message: error.toString(),
          origin: 'sendMessageEncrypted',
        ),
      );
      return false;
    } finally {
      store.dispatch(UpdateRoom(id: room.id, sending: false, reply: Message()));
    }
  };
}
