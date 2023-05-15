import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';

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
            (messagesDecrypted.containsKey(id) ? messagesDecrypted[id] : messagesNormal[id]) ??
            Message())
        .toList();
  }

  return messages;
}

List<Message> roomOutbox(AppState state, String? roomId) {
  return List.from((state.eventStore.outbox[roomId] ?? {}).values);
}

List<Message> reviseMessagesThreaded(Map params) {
  final List<Message> messages = params['messages'] ?? [];
  final Map<String, List<Reaction>> reactions = params['reactions'];

  final messagesMap = appendReactions(
    replaceEdited(messages),
    reactions: reactions,
  );

  return List.from(messagesMap.values);
}

Map<String, Message?> appendReactions(
  Map<String, Message?> messages, {
  required Map<String, List<Reaction>> reactions,
}) {
  // get a list message ids (also reaction keys) that have values in 'reactions'
  final List<String> reactionedMessageIds =
      reactions.keys.where((k) => messages.containsKey(k)).toList();

  // add the parsed list to the message to be handled in the UI
  for (final String messageId in reactionedMessageIds) {
    final reactionList = reactions[messageId];
    if (reactionList != null) {
      messages[messageId] = messages[messageId]!.copyWith(
        // reaction body will be null if redacted
        reactions: reactionList.where((reaction) => reaction.body != null).toList(),
      );
    }
  }

  return messages;
}

///
/// Replace Edited
///
/// Modify the original messsage and append the replacement event ID
/// to the editIds list. Edits will still be saved as individual messages
/// in storage, but will be filtered out at the view layer
///
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
  replacements.sort((b, a) => b.timestamp.compareTo(a.timestamp));

  for (final Message messageEdited in replacements) {
    final relatedEventId = messageEdited.relatedEventId!;
    final messageOriginal = messagesMap[relatedEventId];

    if (messageOriginal != null) {
      final validEdit = messageEdited.sender == messageOriginal.sender;

      if (validEdit) {
        messagesMap[relatedEventId] = messageOriginal.copyWith(
          edited: true,
          body: messageEdited.body,
          msgtype: messageEdited.msgtype,
          editIds: [messageEdited.id!, ...messageOriginal.editIds],
        );
      }
    }
  }

  return messagesMap;
}

///
Message? selectOldestMessage(List<Message> messages, {List<Message>? decrypted}) {
  if (messages.isEmpty) {
    return null;
  }

  final Message oldestMessage = messages.fold(
    messages.last,
    (oldest, msg) => msg.timestamp < oldest.timestamp ? msg : oldest,
  );

  if (decrypted != null && decrypted.isNotEmpty) {
    return decrypted.firstWhere((msg) => msg.id == oldestMessage.id, orElse: () => oldestMessage);
  }

  return oldestMessage;
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
  return message.msgtype == MatrixMessageTypes.text ||
      message.msgtype == MatrixMessageTypes.emote ||
      message.msgtype == MatrixMessageTypes.notice ||
      message.type == EventTypes.encrypted;
}
