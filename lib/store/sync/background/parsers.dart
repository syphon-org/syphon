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

  var roomName;

  if (roomName.isEmpty) {
    roomName = roomNames[room.id] ?? INVALID;
  }

  if (roomName.isEmpty) {
    return '$formattedSender sent a new message.';
  }

  return '$formattedSender sent a new message in $roomName';
}

Future<String> parseMessageTitle({
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
    return 'New Message';
  }

  if (room.invite) {
    return 'New Invite';
  }

  var roomName;

  if (roomName.isEmpty) {
    roomName = roomNames[room.id] ?? INVALID;
  }

  if (roomName.isEmpty) {
    return 'New Message';
  }

  return '$roomName';
}
