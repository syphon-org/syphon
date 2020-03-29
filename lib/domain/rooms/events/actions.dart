import 'dart:convert';

import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/rooms/actions.dart';
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

      final request = buildSendMessageRequest(
        protocol: protocol,
        accessToken: store.state.userStore.user.accessToken,
        homeserver: store.state.userStore.homeserver,
        body: body,
        roomId: room.id,
        requestId: DateTime.now().millisecond.toString(),
      );

      final response = await http.put(
        request['url'],
        headers: request['headers'],
      );

      final data = json.decode(response.body);

      print('sendMessage action completed');
      return true;
    } catch (error) {
      print('[fetchRooms] error: $error');
    } finally {
      store.dispatch(SetSending(room: room, sending: false));
    }
  };
}
