import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/receipts/model.dart';
import 'package:syphon/store/events/redaction/model.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/settings/chat-settings/model.dart';
import 'package:syphon/store/sync/selectors.dart';
import 'package:syphon/store/user/model.dart';

class Sync {
  final Room room;
  final SyncEvents events;
  final Map<String, User> users;
  final Map<String, Receipt> readReceipts;
  final bool? leave;
  final bool? overwrite; // TODO: remove - stops loading limited timeline

  const Sync({
    required this.room,
    required this.events,
    this.readReceipts = const {},
    this.users = const {},
    this.leave,
    this.overwrite,
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

class SyncDetails {
  final bool? invite;
  final bool? limited;
  final bool? overwrite;
  final int? totalMembers;
  final String? currBatch; // current batch, if known from fetchMessages
  final String? lastBatch;
  final String? prevBatch;

  const SyncDetails({
    this.invite,
    this.limited,
    this.overwrite,
    this.currBatch,
    this.lastBatch,
    this.prevBatch,
    this.totalMembers,
  });
}

class SyncMessageDetails {
  final bool? limited;
  final bool? encryptionEnabled;
  final int? lastUpdate;

  const SyncMessageDetails({
    this.limited,
    this.encryptionEnabled,
    this.lastUpdate,
  });
}

class SyncStateDetails {
  final String? name;
  final String? avatarUri;
  final String? topic;
  final String? joinRule;
  final bool? encryptionEnabled;
  final bool? direct;
  final int? lastUpdate;
  final int? namePriority;
  final Map<String, User>? users;
  final Set<String>? userIds;
  final bool? leave;

  const SyncStateDetails({
    this.name,
    this.avatarUri,
    this.topic,
    this.joinRule,
    this.encryptionEnabled,
    this.direct,
    this.lastUpdate,
    this.namePriority,
    this.users,
    this.userIds,
    this.leave,
  });
}

class SyncAccountData {
  final bool? direct;

  const SyncAccountData({
    this.direct,
  });
}

class SyncEphemerals {
  final int lastRead;
  final bool userTyping;
  final List<String> usersTyping;
  final Map<String, Receipt> readReceipts; // eventId indexed

  const SyncEphemerals({
    this.lastRead = 0,
    this.userTyping = false,
    this.usersTyping = const [],
    this.readReceipts = const {},
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
Sync parseSync(
  final Map<String, dynamic> json,
  final Room roomExisting,
  final User currentUser,
  final String? lastSince,
  final List<String> existingIds, {
  final ignoreMessageless = false,
}) {
  final syncDetails = parseDetails(json);

  final events = parseEvents(
    json,
    roomId: roomExisting.id,
    batch: syncDetails.currBatch ?? lastSince,
    prevBatch: syncDetails.prevBatch,
  );

  if (ignoreMessageless) {
    if (events.messages.isEmpty) {
      return Sync(
        room: roomExisting,
        events: events,
      );
    }
  }

  final accountData = parseAccountData(
    events.account,
  );

  final stateDetails = parseState(
    room: roomExisting,
    events: events.state,
    currentUser: currentUser,
    direct: accountData.direct,
  );

  final messageDetails = parseMessages(
    room: roomExisting,
    messages: events.messages,
    existingIds: existingIds,
    prevBatch: syncDetails.prevBatch,
    overwrite: syncDetails.overwrite,
  );

  final ephemerals = parseEphemerals(
    room: roomExisting,
    events: events.ephemeral,
    currentUser: currentUser,
  );

  final room = roomExisting.fromSync(
    lastSince: lastSince,
    accountData: accountData,
    stateDetails: stateDetails,
    messageDetails: messageDetails,
    ephemerals: ephemerals,
    syncDetails: syncDetails,
  );

  if (syncDetails.limited ?? false) {
    log.json({
      'from': '[parseSync]',
      'room': room.name,
      'limited': syncDetails.limited,
      'messages': events.messages.length,
      'lastBatch': syncDetails.lastBatch,
      'prevBatch': syncDetails.prevBatch,
    });
  }

  return Sync(
    room: room,
    events: events,
    users: stateDetails.users ?? {},
    readReceipts: ephemerals.readReceipts,
    // TODO: clear messages if limited was explicitly false from parsed json
    overwrite: syncDetails.overwrite,
    leave: stateDetails.leave,
  );
}

///
/// Parse Sync (Isolate)
///
/// Parse Sync but isolate safe
///
Future<Sync> parseSyncIsolate(Map params) async {
  final json = params['json'] as Map<String, dynamic>;
  final Room roomExisting = params['room'];
  final User currentUser = params['currentUser'];
  final String? lastSince = params['lastSince'];
  final List<String> existingIds = params['existingMessagesIds'];

  return parseSync(
    json,
    roomExisting,
    currentUser,
    lastSince,
    existingIds,
  );
}

///
/// Parse Sync (Threaded)
///
/// Wrapper for compute function
/// allows typesafe declarations inside
/// actions
///
Future<Sync> parseSyncThreaded({
  required final Map<String, dynamic> json,
  required final Room room,
  required final User user,
  required final String? lastSince,
  required final List<String> existingIds,
  final ignoreMessageless = false,
}) async {
  return compute(parseSyncIsolate, {
    'json': json,
    'room': room,
    'currentUser': user,
    'lastSince': lastSince,
    'existingMessagesIds': existingIds,
  });
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

    stateEvents = stateEventsRaw
        .map((event) => Event.fromMatrix(event, roomId: roomId))
        .toList();
  }

  if (json['invite_state'] != null) {
    final List<dynamic> stateEventsRaw = json['invite_state']['events'];

    stateEvents = stateEventsRaw
        .map((event) => Event.fromMatrix(event, roomId: roomId))
        .toList();
  }

  if (json['account_data'] != null) {
    final List<dynamic> accountEventsRaw = json['account_data']['events'];

    accountEvents = accountEventsRaw
        .map((event) => Event.fromMatrix(event, roomId: roomId))
        .toList();
  }

  if (json['ephemeral'] != null) {
    final List<dynamic> ephemeralEventsRaw = json['ephemeral']['events'];

    ephemeralEvents = ephemeralEventsRaw
        .map((event) => Event.fromMatrix(event, roomId: roomId))
        .toList();
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

///
/// Parse Account Data
///
/// Mostly used to assign is_direct
SyncAccountData parseAccountData(
  List<Event> accountDataEvents,
) {
  bool? isDirect;

  try {
    for (final event in accountDataEvents) {
      switch (event.type) {
        case 'm.direct':
          isDirect = true;
          break;
        default:
          break;
      }
    }
  } catch (error) {
    // ignore error processing
  }

  return SyncAccountData(
    direct: isDirect,
  );
}

///
/// Parse Details
///
/// Parsed details about new timeline
/// and batch information
///
SyncDetails parseDetails(Map<String, dynamic> json) {
  bool? invite;
  bool? limited;
  bool? overwrite;
  int? totalMembers;
  String? currBatch;
  String? lastBatch;
  String? prevBatch;

  if (json['overwrite'] != null) {
    overwrite = json['overwrite'];
  }

  if (json['invite_state'] != null) {
    invite = true;
  }

  if (json['timeline'] != null) {
    limited = json['timeline']['limited'];
    lastBatch = json['timeline']['last_batch'];
    currBatch = json['timeline']['curr_batch'];
    prevBatch = json['timeline']['prev_batch'];
  }

  if (json['summary'] != null) {
    totalMembers = json['summary']['m.joined_member_count'];
  }

  return SyncDetails(
    invite: invite,
    limited: limited,
    overwrite: overwrite,
    currBatch: currBatch,
    lastBatch: lastBatch,
    prevBatch: prevBatch,
    totalMembers: totalMembers,
  );
}

///
/// Parse Room State
///
/// Find details of room based on state events
/// follows spec naming priority and thumbnail downloading
///
/// NOTE: purposefully have not abstracted event names
/// it's good to know exactly what you're matching against
/// in the spec for research and comparison
///
SyncStateDetails parseState({
  required Room room,
  required User currentUser,
  required List<Event> events,
  LastUpdateType lastUpdateType = LastUpdateType.Message,
  bool? direct,
}) {
  String? roomName;
  String? avatarUri;
  String? topic;
  String? joinRule;
  bool? encryptionEnabled;
  bool? directNew = direct;
  int? lastUpdateNew;
  bool? leave;

  final usersAdd = <String, User>{};
  final Set<String> userIdsRemove = {};
  final Set<String> userIdsNew = Set.from(room.userIds);

  int namePriority = room.namePriority;

  for (final event in events) {
    try {
      // TODO: enable when setting is available
      // if (lastUpdateType == LastUpdateType.State) {
      //   final timestamp = event.timestamp;
      //   lastUpdateNew = timestamp > room.lastUpdate ? timestamp : room.lastUpdate;
      // }

      switch (event.type) {
        case 'm.room.name':
          if (namePriority > 0) {
            namePriority = 1;
            roomName = event.content['name'];
          }
          break;
        case 'm.room.topic':
          topic = event.content['topic'];
          break;

        case 'm.room.join_rules':
          joinRule = event.content['join_rule'];
          break;

        case 'm.room.canonical_alias':
          if (namePriority > 2) {
            namePriority = 2;
            roomName = event.content['alias'];
          }
          break;
        case 'm.room.aliases':
          if (namePriority > 3) {
            namePriority = 3;
            roomName = event.content['aliases'][0];
          }
          break;
        case 'm.room.avatar':
          if (avatarUri == null) {
            avatarUri = event.content['url'];
          }
          break;

        case 'm.room.member':
          final membership = event.content['membership'];
          final displayName = event.content['displayname'];
          final memberAvatarUri = event.content['avatar_url'];

          // set direct new if it hasn't been set
          directNew = directNew ?? event.content['is_direct'];

          // Cache user to rooms user cache if not present
          if (!usersAdd.containsKey(event.stateKey)) {
            usersAdd[event.stateKey!] = User(
              userId: event.stateKey,
              displayName: displayName,
              avatarUri: memberAvatarUri,
            );
          }

          switch (membership) {
            case 'ban':
            case 'leave':
              userIdsRemove.add(event.stateKey!);

              if (event.stateKey == currentUser.userId) {
                leave = true;
              }
              break;
            default:
              break;
          }

          break;
        case 'm.room.encryption':
          encryptionEnabled = true;
          break;
        case 'm.room.encrypted':
          break;
        default:
          break;
      }
    } catch (error) {
      log.error('[parseState] $error ${event.type}');
    }
  }

  final isDirect = directNew ?? room.direct;
  userIdsNew.addAll(usersAdd.keys);
  userIdsNew.removeWhere((id) => userIdsRemove.contains(id));

  log.json({
    'from': '[isDirect]',
    'id': room.id,
    'room': room.name,
    'isDirect': isDirect,
    'usersAdd': usersAdd.keys.fold('', (String o, u) => '$o, $u'),
    'userIdsRemove': userIdsRemove.fold('', (String o, u) => '$o, $u'),
  });

  // generate direct message room names without a explicitly set name
  if (isDirect) {
    // checks to make sure someone didn't name the room after the authed user
    final badRoomName = roomName != null &&
        currentUser.userId != null &&
        (roomName == currentUser.displayName || roomName == currentUser.userId);

    final isNameDefault = namePriority == 4 && usersAdd.isNotEmpty;

    log.json({
      'from': '[isNameDefault]',
      'id': room.id,
      'room': room.name,
      'badRoomName': badRoomName,
      'isNameDefault': isNameDefault,
    });

    if (badRoomName || isNameDefault) {
      // Filter out number of non current users to show preview of total
      final otherUsers = usersAdd.values.where(
        (user) => user.userId != currentUser.userId,
      );

      log.json({
        'from': '[otherUsers]',
        'id': room.id,
        'room': room.name,
        'isDirect': isDirect,
        'otherUsers': otherUsers.fold('', (String o, u) => o + u.toString()),
      });

      if (otherUsers.isNotEmpty) {
        roomName =
            selectDirectRoomName(currentUser, otherUsers, userIdsNew.length);
        avatarUri = selectDirectRoomAvatar(room, avatarUri, otherUsers);
      }
    }
  }

  return SyncStateDetails(
    name: roomName,
    topic: topic,
    direct: directNew,
    avatarUri: avatarUri,
    joinRule: joinRule,
    namePriority: namePriority,
    lastUpdate: lastUpdateNew,
    encryptionEnabled: encryptionEnabled,
    userIds:
        userIdsNew, // TODO: extract to pivot table for userIds associated by room
    users: usersAdd.isNotEmpty ? usersAdd : null,
    leave: leave,
  );
}

///
/// Parse Room Messages
///
SyncMessageDetails parseMessages({
  required List<Message> messages,
  required List<String> existingIds,
  required Room room,
  String? prevBatch,
  bool? overwrite,
}) {
  try {
    bool? limitedNew;
    int? lastUpdateNew;

    // Converting only message events
    final hasEncrypted = messages.firstWhereOrNull(
      (msg) => msg.type == EventTypes.encrypted,
    );

    // See if the newest message has a greater timestamp
    final latestMessage = messages.firstWhereOrNull(
      (msg) => msg.timestamp > room.lastUpdate,
    );

    if (latestMessage != null) {
      lastUpdateNew = latestMessage.timestamp;
    }

    // limited indicates need to fetch additional data for room timelines
    if (room.limited) {
      // TODO: potentially reimplement, but with batch tokens instead
      // Check to see if the new messages contain those existing in cache
      if (messages.isNotEmpty && existingIds.isNotEmpty) {
        final messageKnown = existingIds.firstWhereOrNull(
          (id) => id == messages[0].id,
        );

        // still limited if messages are all unknown / new
        limitedNew = messageKnown == null;
      }

      // will be null if no other events are available / batched in the timeline (also "end")
      if (prevBatch == null) {
        limitedNew = false;
      }

      // current previous batch is equal to the room's historical previous batch
      if (room.prevBatch == prevBatch) {
        limitedNew = false;
      }

      // if the previous batch is the last known batch, skip pulling it
      if (room.lastBatch == prevBatch) {
        limitedNew = false;
      }

      // if a last known batch hasn't been set (full sync is not complete) stop limited pulls
      if (room.lastBatch == null) {
        limitedNew = false;
      }

      // remove limited status regardless if overwrite enabled
      if (overwrite ?? false) {
        limitedNew = false;

        // pull if the room has no messages, but contains them later in the timeline
        if (messages.isEmpty && existingIds.isEmpty) {
          limitedNew = true;
        }
      }
    }

    return SyncMessageDetails(
      limited: limitedNew,
      lastUpdate: lastUpdateNew,
      encryptionEnabled: hasEncrypted != null,
    );
  } catch (error) {
    log.error('[parseMessages] $error');
    return SyncMessageDetails();
  }
}

///
/// Parse Ephemerals
///
/// Appends ephemeral events (mostly read receipts) to a
/// hashmap of eventIds linking them to users and timestamps
///
SyncEphemerals parseEphemerals({
  required List<Event> events,
  required Room room,
  required User currentUser,
}) {
  bool userTyping = false;
  int lastRead = room.lastRead;
  List<String> usersTypingNow = room.usersTyping;
  final readReceipts = <String, Receipt>{};

  try {
    for (final event in events) {
      switch (event.type) {
        case 'm.typing':
          final List<dynamic> usersTypingList = event.content['user_ids'];
          usersTypingNow = List<String>.from(usersTypingList);
          usersTypingNow.removeWhere(
            (user) => currentUser.userId == user,
          );
          userTyping = usersTypingNow.isNotEmpty;
          break;
        case 'm.receipt':
          final Map<String, dynamic> receiptEventIds = event.content;

          // Filter through every eventId to find receipts
          receiptEventIds.forEach((eventId, receipt) {
            // convert every m.read object to a map of userIds + timestamps for read
            final receiptsNew = Receipt.fromMatrix(eventId, receipt);

            // update the read receipts if that event has no reads yet
            if (!readReceipts.containsKey(eventId)) {
              readReceipts[eventId] = receiptsNew;
            } else {
              // otherwise, add the usersRead to the existing reads
              readReceipts[eventId]!.userReads.addAll(receiptsNew.userReads);
            }
          });
          break;
        default:
          break;
      }
    }
  } catch (error) {
    log.error('[parseEphemerals] ${error.toString()}');
  }

  readReceipts.forEach((key, value) {
    if (value.userReadsMapped!.containsKey(currentUser.userId)) {
      final int readTimestamp = value.userReadsMapped![currentUser.userId];

      if (readTimestamp > lastRead) {
        lastRead = readTimestamp;
      }
    }
  });

  return SyncEphemerals(
    lastRead: lastRead,
    userTyping: userTyping,
    usersTyping: usersTypingNow,
    readReceipts: readReceipts,
  );
}
