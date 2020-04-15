import 'dart:convert';
import 'dart:math';

import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/rooms/actions.dart';
import 'package:Tether/domain/rooms/events/model.dart';
import 'package:Tether/domain/rooms/room/model.dart';
import 'package:Tether/global/libs/matrix/messages.dart';
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

      print('sendMessage action completed $data');

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
