import 'dart:collection';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/user/model.dart';

///
/// Event Parsers
///
/// It's going to be difficult to parse external to room context
/// because so much of the rooms context is gather through the DAG of
/// events. You'd need to pass back both an updated room AND a list of messages
/// to save seperately, or sacrific iterating through the message list again
///
Room parseRoom(Map params) {
  final Map json = params['json'];
  final Room room = params['room'];
  final User currentUser = params['currentUser'];
  final String? lastSince = params['lastSince'];

  // TODO: eventually remove the need for this with modular parsers
  return room.fromSync(
    json: json as Map<String, dynamic>,
    currentUser: currentUser,
    lastSince: lastSince,
  );
}

Map<String, dynamic> parseMessages({
  required Room room,
  List<Message> messages = const [],
  List<Message> existing = const [],
}) {
  bool? limited;
  int lastUpdate = room.lastUpdate;
  final outbox = List<Message>.from(room.outbox);
  final messagesAll = List<Message>.from(existing);

  // Converting only message events
  final hasEncrypted = messages.firstWhereOrNull(
    (msg) => msg.type == EventTypes.encrypted,
  );

  // See if the newest message has a greater timestamp
  if (messages.isNotEmpty && lastUpdate < messages[0].timestamp) {
    lastUpdate = messages[0].timestamp;
  }

  // limited indicates need to fetch additional data for room timelines
  if (room.limited) {
    // Check to see if the new messages contain those existing in cache
    if (messages.isNotEmpty && room.messageIds.isNotEmpty) {
      final String? messageLatest = room.messageIds.firstWhereOrNull(
        (id) => id == messages[0].id,
      );
      // Set limited to false if they now exist
      limited = messageLatest != null;
    }

    // Set limited to false false if
    // - the oldest hash (lastHash) is non-existant
    // - the previous hash (most recent) is non-existant
    // - the oldest hash equals the previously fetched hash
    if (room.lastHash == null ||
        room.prevHash == null ||
        room.lastHash == room.prevHash) {
      limited = false;
    }
  }

  // Combine current and existing messages on unique ids
  messagesAll.addAll(messages);

  // Map messages to ids to filter out ids and outbox
  final messagesAllMap = HashMap<String, dynamic>.fromIterable(
    messagesAll,
    key: (message) => message.id,
    value: (message) => message,
  );

  // Remove outboxed messages
  outbox.removeWhere(
    (message) => messagesAllMap.containsKey(message.id),
  );

  // save messages and unique message id updates
  final messageIdsAll = Set<String>.from(room.messageIds)
    ..addAll(messagesAllMap.keys);

  return {
    'messages': messages,
    'room': room.copyWith(
      outbox: outbox,
      messageIds: messageIdsAll.toList(),
      limited: limited ?? room.limited,
      lastUpdate: lastUpdate,
      encryptionEnabled: room.encryptionEnabled || hasEncrypted != null,
    ),
  };
}

Map<String, dynamic> parseOptions(Map<String, dynamic> json) {
  bool invite;
  bool? limited;
  String? lastHash;
  String? prevHash;

  invite = json['invite_state'] != null;

  if (json['timeline'] != null) {
    limited = json['timeline']['limited'];
    lastHash = json['timeline']['last_hash'];
    prevHash = json['timeline']['prev_batch'];
  }

  return {
    'invite': invite,
    'limited': limited,
    'lastHash': lastHash,
    'prevHash': prevHash,
  };
}

Map<String, dynamic> parseEvents(Map<String, dynamic> json) {
  List<Event> stateEvents = [];
  List<Event> accountEvents = [];
  final List<Message> messageEvents = [];
  List<Event> ephemeralEvents = [];
  final List<Reaction> reactionEvents = [];
  final List<Event> redactedEvents = [];

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

    for (final event in timelineEvents) {
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
  return {
    'stateEvents': stateEvents,
    'accountEvents': accountEvents,
    'messageEvents': messageEvents,
    'redactedEvents': redactedEvents,
    'reactionEvents': reactionEvents,
    'ephemeralEvents': ephemeralEvents,
  };
}
