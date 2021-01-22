// Project imports:
import 'package:syphon/global/values.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/redaction/model.dart';

import './actions.dart';
import '../events/model.dart';
import './state.dart';
import 'package:syphon/store/events/messages/model.dart';

EventStore eventReducer(
    [EventStore state = const EventStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetEvents:
      final roomId = action.roomId;
      final events = Map<String, List<Event>>.from(state.events);
      events[roomId] = action.state;
      return state.copyWith(events: events);

    case SetReactions:
      if (action.reactions.isEmpty) {
        return state;
      }

      final reactionsUpdated = Map<String, List<Reaction>>.from(
        state.reactions,
      );

      for (Reaction reaction in action.reactions ?? []) {
        final exists = reactionsUpdated.containsKey(reaction.relEventId);

        if (exists) {
          final existing = reactionsUpdated[reaction.relEventId];
          if (existing.indexWhere((value) => value.id == reaction.id) == -1) {
            reactionsUpdated[reaction.relEventId] = [...existing, reaction];
          }
        } else {
          reactionsUpdated[reaction.relEventId] = [reaction];
        }
      }

      return state.copyWith(reactions: reactionsUpdated);

    case SetMessages:
      if (state.messages.isEmpty) {
        return state;
      }
      final roomId = action.roomId;
      final messages = Map<String, List<Message>>.from(state.messages);

      final messagesOld = Map<String, Message>.fromIterable(
        messages[roomId] ?? [],
        key: (msg) => msg.id,
        value: (msg) => msg,
      );
      final messagesNew = Map<String, Message>.fromIterable(
        action.messages ?? [],
        key: (msg) => msg.id,
        value: (msg) => msg,
      );

      final messagesAll = messagesOld..addAll(messagesNew);

      messages[roomId] = messagesAll.values.toList();

      return state.copyWith(messages: messages);

    case SetRedactions:
      if (action.redactions.isEmpty) {
        return state;
      }

      final redactions = Map.from(state.redactions);

      final redactionsNew = Map<String, Redaction>.fromIterable(
        action.redactions ?? [],
        key: (redaction) => redaction.id,
        value: (redaction) => redaction,
      );

      return state.copyWith(
        redactions: redactions..addAll(redactionsNew),
      );

    // final messages = Map<String, List<Message>>.from(state.messages);
    // final reactions = Map<String, List<Reaction>>.from(state.reactions);

    // final redactionMap = Map<String, Redaction>.fromIterable(
    //   redactions ?? [],
    //   key: (redaction) => redaction.id,
    //   value: (redaction) => redaction,
    // );

    // final messagesMap = Map<String, Message>.fromIterable(
    //   messages[roomId] ?? [],
    //   key: (msg) => msg.id,
    //   value: (msg) => msg,
    // );

    // // only keep the keys for messages in the room
    // final roomReactions = Map.from(reactions)
    //   ..removeWhere((key, value) => !messagesMap.containsKey(key));

    // // we need to redact the reaction based on the reaction id
    // // not the ID of the event the reaction was for
    // // unfortunately, the redaction does not give us the associated event id
    // // so we pool all the events together and map them on ID
    // // so we don't have to search through them all
    // final reactionsMap = Map<String, Reaction>.fromIterable(
    //   roomReactions.values.expand((e) => e).toList(),
    //   key: (reaction) => (reaction as Reaction).relEventId,
    //   value: (reaction) => reaction,
    // );

    // for (Redaction redaction in redactions) {
    //   final redactedId = redaction.redactId;
    //   final isMessage = messagesMap[redactedId] != null;
    //   final isReaction = reactionsMap[redactedId] != null;

    //   if (isMessage) {
    //     messagesMap[redactedId] = messagesMap[redactedId].copyWith(
    //       body: null,
    //     );
    //   } else if (isReaction) {
    //     final eventId = reactionsMap[redactedId].relEventId;

    //     // you have to keep the reaction in place, otherwise they won't
    //     // know (if fetched again) that it has been redacted
    //     reactions[eventId] = reactions[eventId].map((reaction) {
    //       if (reaction.id == redactedId) {
    //         return reaction.copyWith(body: null);
    //       }
    //       return reaction;
    //     });
    //   }
    // }

    // // replace room messages with updated values
    // messages[roomId] = messagesMap.values.toList();

    // // TODO: consider just checking the redacted map
    // // in a selector before displaying the events
    // return state.copyWith(
    //   messages: messages,
    //   reactions: reactions,
    //   redactions: state.redactions..addAll(redactionMap),
    // );

    case ResetEvents:
      return EventStore();
    default:
      return state;
  }
}
