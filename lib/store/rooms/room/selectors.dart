import 'package:Tether/store/rooms/events/model.dart';
import 'package:Tether/store/rooms/events/selectors.dart';
import 'package:Tether/store/rooms/room/model.dart';

String formatPreviewTopic(String fullTopic, {String defaultTopic}) {
  final topic = fullTopic ?? defaultTopic ?? 'No Topic Available';
  return topic.length > 100
      ? topic.substring(0, 100).replaceAll('\n', ' ')
      : topic;
}

String formatPreviewMessage(String message) {
  return message.replaceAll('\n', ' ');
}

String formatTotalUsers(int totalUsers) {
  return totalUsers.toString();
}

String formatPreview({Room room, Message recentMessage}) {
  // Prioritize drafts for any room, regardless of state
  if (room.draft != null) {
    return 'Draft: ${formatPreviewMessage(room.draft.body)}';
  }

  // Show topic if the user has joined a group but not sent anything (lurkin')
  if (room.messages == null || room.messages.length < 1) {
    print('what ${room.direct}');
    if (room.direct) {
      return 'No messages yet';
    } else {
      return formatPreviewTopic(room.topic, defaultTopic: '');
    }
  }

  final messages = latestMessages(room.messages);
  final previewMessage = formatPreviewMessage(messages[0].body);

  return previewMessage;
}

String formatRoomName({Room room}) {
  final name = room.name;
  return name.length > 22 ? '${name.substring(0, 22)}...' : name;
}

String formatRoomInitials({Room room}) {
  return room.name.substring(0, 2).toUpperCase();
}
