// Project imports:
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';

// TODO: replaces latestMessages() selectors with this
List<Message> latestRoomMessages(AppState state, String roomId) {
  final messagesAll = state.eventStore.messages;

  return messagesAll[roomId] ?? [];
}

List<Message> latestMessages(List<Message> messages) {
  final sortedList = messages ?? [];

  // sort descending
  messages.sort((a, b) {
    if (a.pending && !b.pending) {
      return -1;
    }

    if (a.timestamp > b.timestamp) {
      return -1;
    }
    if (a.timestamp < b.timestamp) {
      return 1;
    }

    return 0;
  });

  return sortedList;
}

List<Message> wrapOutboxMessages({
  List<Message> messages,
  List<Message> outbox,
}) {
  return [outbox, messages].expand((x) => x).toList();
}

bool isTextMessage({Message message}) {
  return message.msgtype == MessageTypes.TEXT ||
      message.msgtype == MessageTypes.EMOTE ||
      message.msgtype == MessageTypes.NOTICE;
}
