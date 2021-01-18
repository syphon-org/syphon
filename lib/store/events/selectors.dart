// Project imports:
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/index.dart';

List<Message> roomMessages(AppState state, String roomId) {
  return state.eventStore.messages[roomId] ?? [];
}

// remove messages from blocked users
List<Message> filterMessages(List<Message> messages, List<String> blocked) {
  return messages
    ..removeWhere(
      (message) => blocked.contains(message.sender),
    );
}

List<Message> replaceEdited(List<Message> messages) {
  final replacements = List<Message>();

  // create a map of messages for O(1) when replacing (O(N))
  final messagesMap = Map<String, Message>.fromIterable(
    messages ?? [],
    key: (msg) => msg.id,
    value: (msg) {
      if (msg.replacement ?? false) {
        replacements.add(msg);
      }

      return msg;
    },
  );

  // sort replacements so they replace each other in order
  // iterate through replacements and modify messages as needed O(M + M)
  replacements.sort((b, a) => a.timestamp.compareTo(b.timestamp));

  for (Message replacement in replacements) {
    if (messagesMap.containsKey(replacement.replacementId)) {
      final replaced = messagesMap[replacement.replacementId];
      messagesMap[replacement.replacementId] = replaced.copyWith(
        body: replacement.body,
        msgtype: replacement.msgtype,
        latestTimestamp: replacement.timestamp,
        edited: true,
      );

      // remove replacements from the returned messages
      messagesMap.remove(replacement.id);
    }
  }

  return List.from(messagesMap.values);
}

List<Message> reduceReactions(
  List<Message> messages,
  List<Reaction> reactions,
) {
  return messages;
}

List<Message> latestMessages(List<Message> messages) {
  final sortedList = List<Message>.from(messages ?? []);

  // sort descending
  sortedList.sort((a, b) {
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
      message.msgtype == MessageTypes.NOTICE ||
      message.type == EventTypes.encrypted;
}
