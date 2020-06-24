import 'package:syphon/global/strings.dart';
import 'package:syphon/store/rooms/events/model.dart';
import 'package:syphon/store/rooms/events/selectors.dart';
import 'package:syphon/store/rooms/room/model.dart';

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

String formatPreview({Room room}) {
  // Prioritize drafts for any room, regardless of state
  if (room.draft != null) {
    return 'Draft: ${formatPreviewMessage(room.draft.body)}';
  }

  // Show topic if the user has joined a group but not sent anything (lurkin')
  if (room.messages == null || room.messages.length < 1) {
    if (room.invite) {
      return 'Invite to chat';
    }
    if (room.direct) {
      return 'No messages yet';
    }

    return formatPreviewTopic(room.topic, defaultTopic: '');
  }

  final messages = latestMessages(room.messages);
  final recentMessage = messages[0];
  var body = formatPreviewMessage(recentMessage.body);

  if (body.isEmpty && recentMessage.ciphertext.isNotEmpty) {
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
