import 'dart:convert';
import 'dart:math';

import 'package:Tether/global/libs/matrix/index.dart';
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

// ThunkAction<AppState> fetchMessageEvents({Room room}) {
//   return (Store<AppState> store) async {
//     try {
//       store.dispatch(UpdateRoom(id: room.id, syncing: true));

//       final messagesJson = await MatrixApi.fetchMessageEvents(
//         protocol: protocol,
//         homeserver: store.state.authStore.user.homeserver,
//         accessToken: store.state.authStore.user.accessToken,
//         roomId: room.id,
//       );

//       final String startTime = messagesJson['start'];
//       final String endTime = messagesJson['end'];
//       final List<dynamic> messagesChunk = messagesJson['chunk'];

//       // TODO: I would really love to use inheritance
//       final List<Message> messages = messagesChunk
//           .map((event) => Message.fromEvent(Event.fromJson(event)))
//           .toList();

//       store.dispatch(SetRoomMessages(
//         id: room.id,
//         messageEvents: messages,
//         startTime: startTime,
//         endTime: endTime,
//       ));
//     } catch (error) {
//       print('[fetchMessageEvents] error $error');
//     } finally {
//       store.dispatch(UpdateRoom(id: room.id, syncing: false));
//     }
//   };
// }

// ThunkAction<AppState> fetchStateEvents({Room room}) {
//   return (Store<AppState> store) async {
//     try {
//       // store.dispatch(SetRoom(room: updatedRoom.copyWith(syncing: true)));
//       store.dispatch(UpdateRoom(id: room.id, syncing: true));

//       final stateEventJson = await MatrixApi.fetchStateEvents(
//         protocol: protocol,
//         homeserver: store.state.authStore.user.homeserver,
//         accessToken: store.state.authStore.user.accessToken,
//         roomId: room.id,
//       );

//       // Convert all of the events and save
//       final List<Event> stateEvents =
//           stateEventJson.map((event) => Event.fromJson(event)).toList();

//       // Add State events to room and toggle syncing
//       final user = store.state.authStore.user;

//       store.dispatch(SetRoomState(
//         id: room.id,
//         state: stateEvents,
//         currentUser: user.displayName,
//       ));

//       final updatedRoom = store.state.roomStore.rooms[room.id];
//       if (updatedRoom.avatarUri != null) {
//         store.dispatch(fetchThumbnail(
//           mxcUri: updatedRoom.avatarUri,
//         ));
//       }
//     } catch (error) {
//       print('[fetchRoomState] error: ${room.id} $error');
//     } finally {
//       store.dispatch(UpdateRoom(id: room.id, syncing: false));
//     }
//   };
// }

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

    final roomInstance = store.state.roomStore.rooms[room.id];

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
