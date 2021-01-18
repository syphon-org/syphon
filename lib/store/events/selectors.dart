// Project imports:
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/index.dart';

List<Message> roomMessages(AppState state, String roomId) {
  return state.eventStore.messages[roomId] ?? [];
}

Map<String, List<Reaction>> selectReactions(AppState state) {
  return state.eventStore.reactions ?? [];
}

// remove messages from blocked users
List<Message> filterBlocked(List<Message> messages, {List<String> blocked}) {
  return messages
    ..removeWhere(
      (message) => blocked.contains(message.sender),
    );
}

List<Message> replaceRelated(
  List<Message> messages, {
  Map<String, List<Reaction>> reactions,
}) {
  final messagesMap = replaceReactions(
    replaceEdited(messages),
    reactions: reactions,
  );

  return List.from(messagesMap.values);
}

Map<String, Message> replaceReactions(
  Map<String, Message> messages, {
  Map<String, List<Reaction>> reactions,
}) {
  // get a list message ids (also reaction keys) that have values in 'reactions'
  final List<String> reactionKeys =
      reactions.keys.where((k) => messages.containsKey(k)).toList();

  // add the parsed list to the message to be handled in the UI
  for (String reactionKey in reactionKeys) {
    final reactionList = reactions[reactionKey];
    if (reactionList != null) {
      messages[reactionKey] = messages[reactionKey].copyWith(
        reactions: reactionList,
      );
    }
  }

  return messages;
}

Map<String, Message> replaceEdited(List<Message> messages) {
  final replacements = List<Message>();

  // create a map of messages for O(1) when replacing (O(N))
  final messagesMap = Map<String, Message>.fromIterable(
    messages ?? [],
    key: (msg) => msg.id,
    value: (msg) {
      if (msg.replacement) {
        replacements.add(msg);
      }

      return msg;
    },
  );

  // sort replacements so they replace each other in order
  // iterate through replacements and modify messages as needed O(M + M)
  replacements.sort((b, a) => a.timestamp.compareTo(b.timestamp));

  for (Message replacement in replacements) {
    if (messagesMap.containsKey(replacement.relatedEventId)) {
      final eventUpdated = messagesMap[replacement.relatedEventId];
      messagesMap[replacement.relatedEventId] = eventUpdated.copyWith(
        body: replacement.body,
        msgtype: replacement.msgtype,
        edits: [replacement, ...(eventUpdated.edits ?? List<Message>())],
        edited: true,
      );

      // remove replacements from the returned messages
      messagesMap.remove(replacement.id);
    }
  }

  return messagesMap;
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
