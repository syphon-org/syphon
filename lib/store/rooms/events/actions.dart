import 'dart:convert';
import 'dart:math';

import 'package:Tether/global/libs/matrix/user.dart';
import 'package:Tether/global/libs/matrix/messages.dart';
import 'package:Tether/global/libs/matrix/rooms.dart';
import 'package:Tether/store/index.dart';
import 'package:Tether/store/media/actions.dart';
import 'package:Tether/store/rooms/actions.dart';
import 'package:Tether/store/rooms/events/model.dart';
import 'package:Tether/store/rooms/room/model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:http/http.dart' as http;

final protocol = DotEnv().env['PROTOCOL'];

final msgtypes = {
  'text': 'm.text',
  'emote': 'm.emote', // TODO: not impliemented
  'notice': 'm.notice', // TODO: not impliemented
  'image': 'm.image', // TODO: not impliemented
  'file': 'm.file', // TODO: not impliemented
  'audio': 'm.audio', // TODO: not impliemented
  'video': 'm.video', // TODO: not impliemented
};

ThunkAction<AppState> fetchMessageEvents({Room room}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(UpdateRoom(id: room.id, syncing: true));

      final request = buildRoomMessagesRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
        roomId: room.id,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      final Map<String, dynamic> messagesJson = json.decode(response.body);
      final String startTime = messagesJson['start'];
      final String endTime = messagesJson['end'];
      final List<dynamic> messagesChunk = messagesJson['chunk'];

      // TODO: I would really love to use inheritance
      final List<Message> messages = messagesChunk
          .map((event) => Message.fromEvent(Event.fromJson(event)))
          .toList();

      store.dispatch(SetRoomMessages(
        id: room.id,
        messageEvents: messages,
        startTime: startTime,
        endTime: endTime,
      ));
    } catch (error) {
      print('[fetchMessageEvents] error $error');
    } finally {
      store.dispatch(UpdateRoom(id: room.id, syncing: false));
    }
  };
}

ThunkAction<AppState> fetchStateEvents({Room room}) {
  return (Store<AppState> store) async {
    try {
      // store.dispatch(SetRoom(room: updatedRoom.copyWith(syncing: true)));
      store.dispatch(UpdateRoom(id: room.id, syncing: true));
      final request = buildRoomStateRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
        roomId: room.id,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      final List<dynamic> rawStateEvents = json.decode(response.body);

      // Convert all of the events and save
      final List<Event> stateEvents =
          rawStateEvents.map((event) => Event.fromJson(event)).toList();

      // Add State events to room and toggle syncing
      final user = store.state.userStore.user;

      store.dispatch(SetRoomState(
        id: room.id,
        state: stateEvents,
        username: user.displayName,
      ));

      final updatedRoom = store.state.roomStore.rooms[room.id];
      if (updatedRoom.avatarUri != null) {
        store.dispatch(fetchThumbnail(
          mxcUri: updatedRoom.avatarUri,
        ));
      }
    } catch (error) {
      print('[fetchRoomState] error: ${room.id} $error');
    } finally {
      store.dispatch(UpdateRoom(id: room.id, syncing: false));
    }
  };
}

ThunkAction<AppState> fetchMemberEvents({String roomId}) {
  return (Store<AppState> store) async {
    try {
      final request = buildFastRoomMembersRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
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
        accessToken: store.state.userStore.user.accessToken,
        homeserver: store.state.userStore.homeserver,
        roomId: roomId,
        userId: store.state.userStore.user.userId,
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

/**
 * Send Room Event (Send Message)
 */
ThunkAction<AppState> sendMessage({
  final body,
  String type = 'm.text',
  Room room,
}) {
  return (Store<AppState> store) async {
    store.dispatch(SetSending(room: room, sending: true));
    try {
      print('[sendMessage] ${type} ${body}');

      // if you're incredibly unlucky, and fast, you could have a problem here
      final String tempId = Random.secure().nextInt(1 << 32).toString();

      // Save unsent message to outbox
      store.dispatch(SaveOutboxMessage(
        id: room.id,
        pendingMessage: Message(
          id: tempId.toString(),
          body: body,
          type: type,
          sender: store.state.userStore.user.userId,
          roomId: room.id,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          pending: true,
          syncing: true,
        ),
      ));

      final request = buildSendMessageRequest(
        protocol: protocol,
        accessToken: store.state.userStore.user.accessToken,
        homeserver: store.state.userStore.homeserver,
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
          sender: store.state.userStore.user.userId,
          roomId: room.id,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          syncing: true,
        ),
      ));

      return true;
    } catch (error) {
      print('[sendMessage] failed to send: $error');
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
      if (message.pending) {
        print("Deleting Message");
        store.dispatch(DeleteOutboxMessage(message: message));
        return;
      }
    } catch (error) {
      print('[deleteMessage] failed to delete $error');
    }
  };
}
