// Project imports:
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/rooms/room/model.dart';

List<Room> availableRooms(List<Room> rooms) {
  return List.from(rooms.where((room) => !room.hidden));
}

String formatPreviewTopic(String fullTopic, {String defaultTopic}) {
  final topic = fullTopic ?? defaultTopic ?? 'No Topic Available';
  return topic.length > 100
      ? topic.substring(0, 100).replaceAll('\n', ' ')
      : topic;
}

String formatPreviewMessage(String body) {
  return body.replaceAll('\n', ' ');
}

String formatTotalUsers(int totalUsers) {
  return totalUsers.toString();
}

String formatPreview({Room room, Message message}) {
  // Prioritize drafts for any room, regardless of state
  if (room.draft != null && room.draft.body != null) {
    return 'Draft: ${formatPreviewMessage(room.draft.body)}';
  }

  // Show topic if the user has joined a group but not sent
  if (message == null) {
    if (room.invite) {
      return 'Invite to chat';
    }

    if (room.topic == null || room.topic.length < 1) {
      return 'No messages yet';
    }

    return formatPreviewTopic(room.topic, defaultTopic: '');
  }

  if (message.body == '' || message.body == null) {
    return 'This message was deleted';
  }

  // sort messages found
  var body = formatPreviewMessage(message.body);

  if (message.type == EventTypes.encrypted && body.isEmpty) {
    body = Strings.contentEncryptedMessage.replaceAll('[]', '');
  }

  return body;
}

String formatRoomName({Room room}) {
  final name = room.name;
  return name.length > 22 ? '${name.substring(0, 22)}...' : name;
}

String formatRoomInitials({Room room}) {
  return room.name.substring(0, 2).toUpperCase();
}
