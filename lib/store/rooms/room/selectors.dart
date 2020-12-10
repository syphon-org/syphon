// Project imports:
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/events/selectors.dart';
import 'package:syphon/store/rooms/room/model.dart';

List<Room> availableRooms(List<Room> rooms, {List<String> hidden = const []}) {
  return List.from(rooms.where((room) => !hidden.contains(room.id)));
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

String formatPreview({Room room, List<Message> messages}) {
  // Prioritize drafts for any room, regardless of state
  if (room.draft != null && room.draft.body != null) {
    return 'Draft: ${formatPreviewMessage(room.draft.body)}';
  }

  // Show topic if the user has joined a group but not sent anything (lurkin')

  if (messages == null || messages.length < 1) {
    if (room.invite) {
      return 'Invite to chat';
    }

    if (room.topic == null || room.topic.length < 1) {
      return 'No messages yet';
    }

    return formatPreviewTopic(room.topic, defaultTopic: '');
  }

  // sort messages found
  final recentMessage = messages[0];
  var body = formatPreviewMessage(recentMessage.body);

  if (recentMessage.type == EventTypes.encrypted && body.isEmpty) {
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
