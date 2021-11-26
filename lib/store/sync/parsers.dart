import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/events/ephemeral/m.read/model.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/redaction/model.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/user/model.dart';

class Sync {
  final Room room;
  // final List<Event> state; // TODO:
  final List<Message> messages;
  final List<Reaction> reactions;
  final List<Redaction> redactions;
  final Map<String, User> users;
  final Map<String, ReadReceipt> readReceipts;

  const Sync({
    required this.room,
    // this.state = const [], // TODO:
    this.reactions = const [],
    this.redactions = const [],
    this.messages = const [],
    this.readReceipts = const {},
    this.users = const {},
  });
}

class SyncDetails {
  final bool? invite;
  final bool? limited;
  final String? currBatch; // current batch, if known from fetchMessages
  final String? lastBatch;
  final String? prevBatch;

  const SyncDetails({
    this.invite,
    this.limited,
    this.currBatch,
    this.lastBatch,
    this.prevBatch,
  });
}

class SyncEvents {
  final List<Event> state;
  final List<Event> account;
  final List<Event> ephemeral;
  final List<Message> messages;
  final List<Reaction> reactions;
  final List<Redaction> redactions;

  const SyncEvents({
    this.state = const [],
    this.account = const [],
    this.ephemeral = const [],
    this.messages = const [],
    this.reactions = const [],
    this.redactions = const [],
  });
}

///
/// Parse Sync
///
/// Not all events are needed to derive new information about the room
///
/// Existing messages are used to check if a room has backfilled to a
/// previously known position of chat / messages
///
Sync parseSync(Map params) {
  final Map<String, dynamic> json = params['json'] as Map<String, dynamic>;
  final Room roomExisting = params['room'];
  final User currentUser = params['currentUser'];
  final String? lastSince = params['lastSince'];
  final List<Message> existingMessages = params['existingMessages'];
  final existingIds = existingMessages.map((m) => m.id ?? '').toList();

  final details = parseDetails(json);
  final events = parseEvents(
    json,
    roomId: roomExisting.id,
    batch: details.currBatch ?? lastSince,
    prevBatch: details.prevBatch,
  );

  if (details.limited != null) {
    printInfo(
      '[parseSync] ${roomExisting.id} limited ${details.limited} lastBatch ${details.lastBatch != null} prevBatch ${details.prevBatch != null}',
    );
  }

  final room = roomExisting.fromEvents(
    events: events,
    lastSince: lastSince,
    currentUser: currentUser,
    limited: details.limited,
    lastBatch: details.lastBatch,
    prevBatch: details.prevBatch,
    existingIds: existingIds,
  );

  // TODO: remove with separate parsers, solve the issue of redundant passes over this data
  final users = Map<String, User>.from(room.usersTEMP);
  final readReceipts = Map<String, ReadReceipt>.from(room.readReceiptsTEMP ?? {});

  final roomUpdated = room.copyWith(
    usersTEMP: <String, User>{},
    readReceiptsTEMP: <String, ReadReceipt>{},
  );

  return Sync(
    // state: state,
    users: users,
    room: roomUpdated,
    messages: events.messages,
    reactions: events.reactions,
    redactions: events.redactions,
    readReceipts: readReceipts,
  );
}

SyncDetails parseDetails(Map<String, dynamic> json) {
  bool invite;
  bool? limited;
  String? currBatch;
  String? lastBatch;
  String? prevBatch;

  invite = json['invite_state'] != null;

  if (json['timeline'] != null) {
    limited = json['timeline']['limited'];
    lastBatch = json['timeline']['last_batch'];
    currBatch = json['timeline']['curr_batch'];
    prevBatch = json['timeline']['prev_batch'];
  }

  return SyncDetails(
    invite: invite,
    limited: limited,
    currBatch: currBatch,
    lastBatch: lastBatch,
    prevBatch: prevBatch,
  );
}

///
/// Parse Events
///
/// Consider assigning roomId to a message at the cold storage layer
/// there's several areas we could want the message roomId independent of
/// the room itself. Relatively safe to remove from the message object
/// if the message class in terms of cruft or for performance.
///
SyncEvents parseEvents(
  Map<String, dynamic> json, {
  String? roomId,
  String? batch,
  String? prevBatch,
}) {
  List<Event> stateEvents = [];
  List<Event> accountEvents = [];
  List<Event> ephemeralEvents = [];
  final List<Message> messageEvents = [];
  final List<Reaction> reactionEvents = [];
  final List<Redaction> redactionEvents = [];

  if (json['state'] != null) {
    final List<dynamic> stateEventsRaw = json['state']['events'];

    stateEvents = stateEventsRaw.map((event) => Event.fromMatrix(event, roomId: roomId)).toList();
  }

  if (json['invite_state'] != null) {
    final List<dynamic> stateEventsRaw = json['invite_state']['events'];

    stateEvents = stateEventsRaw.map((event) => Event.fromMatrix(event, roomId: roomId)).toList();
  }

  if (json['account_data'] != null) {
    final List<dynamic> accountEventsRaw = json['account_data']['events'];

    accountEvents =
        accountEventsRaw.map((event) => Event.fromMatrix(event, roomId: roomId)).toList();
  }

  if (json['ephemeral'] != null) {
    final List<dynamic> ephemeralEventsRaw = json['ephemeral']['events'];

    ephemeralEvents =
        ephemeralEventsRaw.map((event) => Event.fromMatrix(event, roomId: roomId)).toList();
  }

  if (json['timeline'] != null) {
    final List<dynamic> timelineEventsRaw = json['timeline']['events'];

    final List<Event> timelineEvents = List.from(
      timelineEventsRaw.map((event) => Event.fromMatrix(
            event,
            roomId: roomId,
            batch: batch,
            prevBatch: prevBatch,
          )),
    );

    for (final Event event in timelineEvents) {
      switch (event.type) {
        case EventTypes.message:
        case EventTypes.encrypted:
          messageEvents.add(Message.fromEvent(event));
          break;
        case EventTypes.reaction:
          reactionEvents.add(Reaction.fromEvent(event));
          break;
        case EventTypes.redaction:
          redactionEvents.add(Redaction.fromEvent(event));
          break;
        default:
          stateEvents.add(event);
          break;
      }
    }
  }

  return SyncEvents(
    state: stateEvents,
    account: accountEvents,
    ephemeral: ephemeralEvents,
    redactions: redactionEvents,
    reactions: reactionEvents,
    messages: messageEvents,
  );
}
