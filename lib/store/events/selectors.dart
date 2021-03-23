// Project imports:
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/redactions/model.dart';
import 'package:syphon/store/index.dart';

List<Message> roomMessages(AppState state, String roomId) {
  return List.from(state.eventStore.messages[roomId] ?? []);
}

Map<String, List<Reaction>> selectReactions(AppState state) {
  return state.eventStore.reactions ?? [];
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
