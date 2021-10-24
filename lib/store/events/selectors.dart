import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/redaction/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/user/model.dart';

List<Message> roomMessages(AppState state, String? roomId) {
  final room = state.roomStore.rooms[roomId] ?? Room(id: '');
  var messages = (state.eventStore.messages[roomId] ?? []).toList();

  // If encryption is enabled, combine the decrypted event cache
  if (room.encryptionEnabled) {
    final decrypted = state.eventStore.messagesDecrypted[roomId] ?? [];

    final messagesNormal = Map<String, Message>.fromIterable(
      messages,
      key: (msg) => msg.id,
      value: (msg) => msg,
    );

    final messagesDecrypted = Map<String, Message>.fromIterable(
      decrypted,
      key: (msg) => msg.id,
      value: (msg) => msg,
    );

    messages = messagesNormal.keys
        .map((id) =>
            (messagesDecrypted.containsKey(id) ? messagesDecrypted[id] : messagesNormal[id]) ?? Message())
        .toList();
  }

  return messages;
}

List<Message> roomOutbox(AppState state, String? roomId) {
  return List.from((state.eventStore.outbox[roomId] ?? {}).values);
}

Map<String, List<Reaction>> selectReactions(AppState state) {
  return state.eventStore.reactions;
}

// remove messages from blocked users
List<Message> filterMessages(
  List<Message> messages,
  AppState state,
) {
  final blocked = state.userStore.blocked;

  // TODO: remove the replacement filter here, should be managed by the mutators
  return messages
    ..removeWhere(
      (message) => blocked.contains(message.sender) || message.replacement,
    );
}

List<Message> reviseMessagesBackground(Map params) {
  final List<Message> messages = params['messages'] ?? [];
  final Map<String, Redaction> redactions = params['redactions'];
  final Map<String, List<Reaction>> reactions = params['reactions'];

  return reviseMessagesFilter(messages, redactions, reactions);
}

List<Message> reviseMessagesFilter(
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

Map<String, Message?> filterRedactions(
  Map<String, Message?> messages, {
  required Map<String, Redaction> redactions,
}) {
  // get a list message ids (also reaction keys) that have values in 'reactions'
  redactions.forEach((key, value) {
    if (messages.containsKey(key)) {
      messages[key] = messages[key]!.copyWith(body: null);
    }
  });

  return messages;
}

Map<String, Message?> appendReactions(
  Map<String, Message?> messages, {
  Map<String, Redaction>? redactions,
  required Map<String, List<Reaction>> reactions,
}) {
  // get a list message ids (also reaction keys) that have values in 'reactions'
  final List<String> reactionedMessageIds = reactions.keys.where((k) => messages.containsKey(k)).toList();

  // add the parsed list to the message to be handled in the UI
  for (String messageId in reactionedMessageIds) {
    final reactionList = reactions[messageId];
    if (reactionList != null) {
      messages[messageId] = messages[messageId]!.copyWith(
        reactions: reactionList
            .where(
              (reaction) => !redactions!.containsKey(reaction.id),
            )
            .toList(),
      );
    }
  }

  return messages;
}

Map<String, Message?> replaceEdited(List<Message> messages) {
  final replacements = <Message>[];

  // create a map of messages for O(1) when replacing O(N)
  final messagesMap = Map<String, Message>.fromIterable(
    messages,
    key: (message) => message.id,
    value: (message) {
      if ((message as Message).replacement) {
        replacements.add(message);
      }

      return message;
    },
  );

  // sort replacements so they replace each other in order
  // iterate through replacements and modify messages as needed O(M + M)
  replacements.sort((b, a) => a.timestamp.compareTo(b.timestamp));

  for (Message messageEdited in replacements) {
    final messageIdOriginal = messageEdited.relatedEventId!;
    final messageOriginal = messagesMap[messageIdOriginal];

    if (messageOriginal != null) {
      final validEdit = messageEdited.sender == messageOriginal.sender;

      if (validEdit) {
        messagesMap[messageIdOriginal] = messageOriginal.copyWith(
          edited: true,
          body: messageEdited.body,
          msgtype: messageEdited.msgtype,
          edits: [messageOriginal, ...(messageOriginal.edits)],
        );
      }
    }

    // remove replacements from the returned messages
    messagesMap.remove(messageEdited.id);
  }

  return messagesMap;
}

Message? latestMessage(List<Message> messages, {Room? room, List<Message>? decrypted}) {
  if (messages.isEmpty) {
    return null;
  }

  final Message latestMessage = messages.fold(
    messages[0],
    (latest, msg) => msg.timestamp > latest.timestamp ? msg : latest,
  );

  if (room != null && decrypted != null && room.encryptionEnabled && decrypted.isNotEmpty) {
    return decrypted.firstWhere((msg) => msg.id == latestMessage.id, orElse: () => latestMessage);
  }

  return latestMessage;
}

List<Message> latestMessages(List<Message> messages) {
  final sortedList = messages;

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

List<Message> combineOutbox({List<Message>? messages, List<Message>? outbox}) {
  return [outbox, messages].expand((x) => x!).toList();
}

bool isTextMessage({required Message message}) {
  return message.msgtype == MessageTypes.TEXT ||
      message.msgtype == MessageTypes.EMOTE ||
      message.msgtype == MessageTypes.NOTICE ||
      message.type == EventTypes.encrypted;
}

bool isDeletable({Message? message, User? user}){
  return false;
}
