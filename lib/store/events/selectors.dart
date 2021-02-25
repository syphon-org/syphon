// Project imports:
import 'dart:async';

import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/redaction/model.dart';
import 'package:syphon/store/index.dart';

List<Message> roomMessages(AppState state, String roomId) {
  return List.from(state.eventStore.messages[roomId] ?? []);
}

Map<String, List<Reaction>> selectReactions(AppState state) {
  return state.eventStore.reactions ?? [];
}

// remove messages from blocked users
List<Message> filterMessages(
  List<Message> messages,
  AppState state,
) {
  final blocked = state.userStore.blocked;

  return messages
    ..removeWhere(
      (message) => blocked.contains(message.sender),
    );
}

List<Message> reviseMessages(
  List<Message> messages,
  AppState state,
) {
  final reactions = selectReactions(state);
  final redactions = state.eventStore.redactions;

  return reviseMessagesAlt(messages, redactions, reactions);
}

List<Message> reviseMessagesAlt(
  List<Message> messages,
  Map<String, Redaction> redactions,
  Map<String, List<Reaction>> reactions,
) {
  final messagesMap = filterRedactions(
    appendReactions(
      replaceEdited(messages),
      reactions: reactions,
      redactions: redactions,
    ),
    redactions: redactions,
  );

  return List.from(messagesMap.values);
}

List<Message> reviseMessagesBackground(Map params) {
  List<Message> messages = params['messages'];
  Map<String, Redaction> redactions = params['redactions'];
  Map<String, List<Reaction>> reactions = params['reactions'];

  return reviseMessagesAlt(messages, redactions, reactions);
}

Map<String, Message> filterRedactions(
  Map<String, Message> messages, {
  Map<String, Redaction> redactions,
}) {
  // get a list message ids (also reaction keys) that have values in 'reactions'
  redactions.forEach((key, value) {
    if (messages.containsKey(key)) {
      messages[key] = messages[key].copyWith(body: null);
    }
  });

  return messages;
}

Map<String, Message> appendReactions(
  Map<String, Message> messages, {
  Map<String, Redaction> redactions,
  Map<String, List<Reaction>> reactions,
}) {
  // get a list message ids (also reaction keys) that have values in 'reactions'
  final List<String> reactionedMessageIds =
      reactions.keys.where((k) => messages.containsKey(k)).toList();

  // add the parsed list to the message to be handled in the UI
  for (String messageId in reactionedMessageIds) {
    final reactionList = reactions[messageId];
    if (reactionList != null) {
      messages[messageId] = messages[messageId].copyWith(
        reactions: reactionList
            .where(
              (reaction) => !redactions.containsKey(reaction.id),
            )
            .toList(),
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
    final messageId = replacement.relatedEventId;
    if (messagesMap.containsKey(messageId)) {
      final messageEdited = messagesMap[messageId];

      messagesMap[messageId] = messageEdited.copyWith(
        edited: true,
        body: replacement.body,
        msgtype: replacement.msgtype,
        edits: [messageEdited, ...(messageEdited.edits ?? List<Message>())],
      );

      // remove replacements from the returned messages
      messagesMap.remove(replacement.id);
    }
  }

  return messagesMap;
}

Message latestMessage(List<Message> messages) {
  // sort descending
  if (messages.isEmpty) {
    return null;
  }

  return messages.fold(messages[0],
      (newest, msg) => msg.timestamp > newest.timestamp ? msg : newest);
}

List<Message> latestMessages(List<Message> messages) {
  final sortedList = messages ?? [];

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

List<Message> combineOutbox({
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
