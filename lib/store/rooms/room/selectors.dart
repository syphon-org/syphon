// Project imports:
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/rooms/room/model.dart';

List<Room> availableRooms(List<Room> rooms) {
  return List.from(rooms.where((room) => !room.hidden));
}

String formatPreviewTopic(String? fullTopic) {
  final topic = fullTopic ?? Strings.contentTopicEmpty;
  final topicTruncated = topic.length > 100 ? topic.substring(0, 100) : topic;
  return topicTruncated.replaceAll('\n', ' ');
}

String formatPreviewMessage(String body) {
  return body.replaceAll('\n', ' ');
}

String formatTotalUsers(int totalUsers) {
  return totalUsers.toString();
}

String formatPreview({required Room room, Message? message}) {
  // Prioritize drafts for any room, regardless of state
  if (room.draft != null && room.draft!.body != null) {
    return 'Draft: ${formatPreviewMessage(room.draft!.body!)}';
  }

  // Show topic if the user has joined a group but not sent
  if (message == null) {
    // romm is just an invite
    if (room.invite) {
      return 'Invite to chat';
    }

    // room was created, but no messages or topic
    if (room.topic == null || room.topic!.length < 1) {
      return 'No messages yet';
    }

    // show the topic as the preview message
    return formatPreviewTopic(room.topic);
  }

  // message was deleted
  if (message.type != EventTypes.encrypted &&
      (message.body == '' || message.body == null)) {
    return 'This message was deleted';
  }

  // message hasn't been decrypted
  if (message.type == EventTypes.encrypted && message.body!.isEmpty) {
    return Strings.contentEncryptedMessage;
  }

  return formatPreviewMessage(message.body!);
}

String formatRoomName({required Room room}) {
  final name = room.name!;
  return name.length > 22 ? '${name.substring(0, 22)}...' : name;
}

String formatRoomInitials({required Room room}) {
  return room.name!.substring(0, 2).toUpperCase();
}
