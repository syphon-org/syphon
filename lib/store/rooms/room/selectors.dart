import 'package:Tether/store/rooms/events/model.dart';
import 'package:Tether/store/rooms/events/selectors.dart';
import 'package:Tether/store/rooms/room/model.dart';

String formatPreviewTopic(String fullTopic, {String defaultTopic}) {
  final topic = fullTopic ?? defaultTopic ?? 'No Topic Available';
  return topic.length > 100
      ? topic.substring(0, 100).replaceAll('\n', ' ')
      : topic;
}

String formatTotalUsers(int totalUsers) {
  return totalUsers.toString();
}

String formatPreview({Room room, Message recentMessage}) {
  if (room == null) {
    return 'No preview available';
  }

  if (room.messages == null || room.messages.length < 1) {
    return formatPreviewTopic(room.topic, defaultTopic: 'No Preview Available');
  }

  final messages = latestMessages(room.messages);
  final previewMessage = messages[0].body;
  final shortened = previewMessage.length > 42;
  final preview = shortened
      ? previewMessage.substring(0, 42).replaceAll('\n', '')
      : previewMessage;

  return shortened ? '$preview...' : preview;
}

String formatRoomName({Room room}) {
  final name = room.name;
  return name.length > 22 ? '${name.substring(0, 22)}...' : name;
}

String formatRoomInitials({Room room}) {
  return room.name.substring(0, 2).toUpperCase();
}
