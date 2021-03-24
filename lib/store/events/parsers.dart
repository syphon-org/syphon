/**
 * 
 * Event Parsers
 * 
 * It's going to be difficult to parse external to room context
 * because so much of the rooms context is gathered through the DAG of
 * events. You'd need to pass back both an updated room AND a list of messages
 * to save seperately, or sacrific iterating through the message list again
 * 
 */

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/redactions/model.dart';

part 'parsers.freezed.dart';

@freezed
abstract class EventPayload with _$EventPayload {
  factory EventPayload({
    List<Event> state,
    List<Event> account,
    List<Message> messages,
    List<Reaction> reactions,
    List<Redaction> redactions,
    List<Event> ephemeral,
  }) = _EventPayload;
}

EventPayload parseEvents(Map<String, dynamic> json) {
  List<Event> stateEvents = [];
  List<Event> accountEvents = [];
  List<Message> messageEvents = [];
  List<Event> ephemeralEvents = [];
  List<Reaction> reactionEvents = [];
  List<Event> redactedEvents = [];

  if (json['state'] != null) {
    final List<dynamic> stateEventsRaw = json['state']['events'];

    stateEvents =
        stateEventsRaw.map((event) => Event.fromMatrix(event)).toList();
  }

  if (json['invite_state'] != null) {
    final List<dynamic> stateEventsRaw = json['invite_state']['events'];

    stateEvents =
        stateEventsRaw.map((event) => Event.fromMatrix(event)).toList();
  }

  if (json['ephemeral'] != null) {
    final List<dynamic> ephemeralEventsRaw = json['ephemeral']['events'];

    ephemeralEvents =
        ephemeralEventsRaw.map((event) => Event.fromMatrix(event)).toList();
  }

  if (json['account_data'] != null) {
    final List<dynamic> accountEventsRaw = json['account_data']['events'];

    accountEvents =
        accountEventsRaw.map((event) => Event.fromMatrix(event)).toList();
  }

  if (json['timeline'] != null) {
    final List<dynamic> timelineEventsRaw = json['timeline']['events'];

    final List<Event> timelineEvents = List.from(
      timelineEventsRaw.map((event) => Event.fromMatrix(event)),
    );

    for (Event event in timelineEvents) {
      switch (event.type) {
        case EventTypes.message:
        case EventTypes.encrypted:
          // deleted messages check
          messageEvents.add(Message.fromEvent(event));
          break;
        case EventTypes.reaction:
          // deleted messages check
          reactionEvents.add(Reaction.fromEvent(event));
          break;
        case EventTypes.redaction:
          redactedEvents.add(event);
          break;
        default:
          stateEvents.add(event);
          break;
      }
    }
  }

  return EventPayload(
    state: stateEvents,
    account: accountEvents,
    messages: messageEvents,
    reactions: reactionEvents,
    redactions: redactedEvents,
    ephemeral: ephemeralEvents,
  );
}
