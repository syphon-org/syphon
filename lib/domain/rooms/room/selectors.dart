import 'package:Tether/domain/rooms/events/model.dart';
import 'package:Tether/domain/rooms/events/selectors.dart';
import 'package:Tether/domain/rooms/room/model.dart';

String formatPreview({Room room, Message recentMessage}) {
  if (room == null) {
    return 'No preview available';
  }

  if (room.messages == null || room.messages.length < 1) {
    return room.topic ?? 'No Preview Available';
  }

  final previewMessage = sortedMessages(room.messages)[0].body;
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
