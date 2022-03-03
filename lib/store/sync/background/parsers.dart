import 'package:syphon/global/strings.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/user/selectors.dart';

const String INVALID = '';

String parseMessageNotification({
  required Room room,
  required Message message,
  required String currentUserId,
  required Map<String, String> roomNames,
  required String protocol,
  required String homeserver,
}) {
  final String? messageSender = message.sender;
  final String formattedSender = trimAlias(messageSender);

  if (formattedSender.isEmpty || message.sender == currentUserId) {
    return INVALID;
  }

  if (room.direct) {
    return Strings.notificationSentNewMessage(formattedSender);
  }

  if (room.invite) {
    return Strings.notificationInvitedToChat(formattedSender);
  }

  String roomName = INVALID;

  if (roomName.isEmpty) {
    roomName = roomNames[room.id] ?? INVALID;
  }

  if (roomName.isEmpty) {
    return Strings.notificationSentNewMessage(formattedSender);
  }

  return Strings.notificationSentNewMessageInRoom(formattedSender, roomName);
}

String parseMessageTitle({
  required Room room,
  required Message message,
  required String currentUserId,
  required Map<String, String> roomNames,
  required String protocol,
  required String homeserver,
}) {
  final String? messageSender = message.sender;
  final String formattedSender = trimAlias(messageSender);

  if (formattedSender.isEmpty || message.sender == currentUserId) {
    return INVALID;
  }

  if (room.direct) {
    return Strings.notificationNewMessage;
  }

  if (room.invite) {
    return Strings.notificationNewInvite;
  }

  String roomName = INVALID;

  if (roomName.isEmpty) {
    roomName = roomNames[room.id] ?? INVALID;
  }

  if (roomName.isEmpty) {
    return Strings.notificationNewMessage;
  }

  return roomName;
}
