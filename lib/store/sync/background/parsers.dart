import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/user/selectors.dart';

const String INVALID = '';

Future<String> parseMessageNotification({
  required Room room,
  required Message message,
  required String currentUserId,
  required Map<String, String> roomNames,
  required String protocol,
  required String homeserver,
}) async {
  final String? messageSender = message.sender;
  final String formattedSender = trimAlias(messageSender);

  if (formattedSender.isEmpty || message.sender == currentUserId) {
    return INVALID;
  }

  if (room.direct) {
    return '$formattedSender sent a new message.';
  }

  if (room.invite) {
    return '$formattedSender invited you to chat.';
  }

  var roomName = room.name ?? INVALID;

  if (roomName.isEmpty) {
    roomName = roomNames[room.id] ?? INVALID;
  }

  if (roomName.isEmpty) {
    return '$formattedSender sent a new message.';
  }
  // try {
  //   final roomNameList = await MatrixApi.fetchRoomName(
  //     protocol: protocol,
  //     homeserver: homeserver,
  //     accessToken: accessToken,
  //     roomId: message.roomId ?? room.id,
  //   );

  //   roomName = roomNameList[roomNameList.length - 1];
  //   roomName = roomName..replaceAll('#', '').replaceAll(r'\:.*', '');
  // } catch (error) {
  //   print('[BackgroundSync] failed to fetch & parse room name ${room.id}');
  // }

  return '$formattedSender sent a new message in $roomName';
}
