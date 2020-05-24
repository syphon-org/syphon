import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:Tether/global/libs/hive/index.dart';
import 'package:Tether/global/libs/matrix/index.dart';
import 'package:Tether/global/libs/matrix/user.dart';
import 'package:Tether/global/libs/matrix/messages.dart';
import 'package:Tether/store/index.dart';
import 'package:Tether/store/rooms/actions.dart';
import 'package:Tether/store/rooms/events/model.dart';
import 'package:Tether/store/rooms/room/model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:http/http.dart' as http;

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
 * Pulls next message events remotely from homeserverr
 */
ThunkAction<AppState> fetchMessageEvents({
  Room room,
  int limit = 10,
}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(UpdateRoom(id: room.id, syncing: true));

      print(
        '[fetchMessageEvents] ${room.toHash}  ${room.prevHash} ${room.prevHash} pre-fetch',
      );

      final String from = room.toHash ?? room.fromHash ?? room.prevHash;

      // TODO: pulling all messages since last since, no "limit"
      // final String to = room.fromHash != room.prevHash ? room.prevHash : null;

      // Pull starting at "to" of last fetch
      // or from the point of last fetch || /sync
      final Map messagesJson = await MatrixApi.fetchMessageEvents(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        from: from,
        roomId: room.id,
        limit: limit,
      );

      final String toHash = messagesJson['end'];
      final String fromHash = messagesJson['start'];
      final List<dynamic> messages = messagesJson['chunk'];

      print('[fetchMessageEvents] $fromHash $toHash');
      print('[fetchMessageEvents] ${messages.length}');

      messages.forEach((message) {
        print('${message['sender']} ${message['content']}');
      });

      store.dispatch(syncRooms(
        {
          '${room.id}': {
            'timeline': {
              'to': toHash,
              'from': fromHash,
              'events': messages,
            }
          },
        },
      ));

      // Have an equivalent json parser for cold storage?
      // store.dispatch(syncStorage());
    } catch (error) {
      print('[fetchMessageEvents] error $error');
    } finally {
      store.dispatch(UpdateRoom(id: room.id, syncing: false));
    }
  };
}

/**
 * DEPRECATED: paginating state events can only be 
 * done from full state /sync data
 */
ThunkAction<AppState> fetchStateEvents({Room room}) {
  return (Store<AppState> store) async {};
}

ThunkAction<AppState> fetchMemberEvents({String roomId}) {
  return (Store<AppState> store) async {
    try {
      final request = buildFastRoomMembersRequest(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        roomId: roomId,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      final data = json.decode(response.body);

      if (data['errcode'] != null) {
        throw data['error'];
      }

      // Convert rooms to rooms
      print('[fetchMemberEvents] TESTING $data');
    } catch (error) {
      print('[fetchMemberEvents] error $error');
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

ThunkAction<AppState> sendTyping({
  String roomId,
  bool typing = false,
}) {
  return (Store<AppState> store) async {
    try {
      // Skip if typing indicators are disabled
      if (!store.state.settingsStore.typingIndicators) {
        print('[sendTyping] typing indicators are disabled $typing');
        return;
      }

      print('[sendTyping] pushing $typing');
      final request = buildSendTypingRequest(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: roomId,
        userId: store.state.authStore.user.userId,
        typing: typing,
      );

      final response = await http.put(
        request['url'],
        headers: request['headers'],
        body: json.encode(request['body']),
      );

      final data = json.decode(response.body);
      if (data['errcode'] != null) {
        throw data['error'];
      }
    } catch (error) {
      print('[toggleTyping] $error');
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

      final request = buildSendMessageRequest(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        messageBody: body,
        roomId: room.id,
        requestId: DateTime.now().millisecond.toString(),
      );

      final response = await http.put(
        request['url'],
        headers: request['headers'],
        body: json.encode(request['body']),
      );

      final data = json.decode(response.body);
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
