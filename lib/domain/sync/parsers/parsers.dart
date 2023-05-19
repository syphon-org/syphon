// ignore_for_file: unnecessary_this

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import 'package:syphon/domain/events/messages/model.dart';
import 'package:syphon/domain/events/model.dart';
import 'package:syphon/domain/events/reactions/model.dart';
import 'package:syphon/domain/events/receipts/model.dart';
import 'package:syphon/domain/events/redaction/model.dart';
import 'package:syphon/domain/rooms/room/model.dart';
import 'package:syphon/domain/sync/selectors.dart';
import 'package:syphon/domain/user/model.dart';

import 'package:syphon/global/libraries/matrix/events/types.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';

class SyncDetails {
  final bool? leave;
  // TODO: clear messages if limited was explicitly false from parsed json
  final bool? overwrite;
  final String? currBatch;
  final String? prevBatch;

  const SyncDetails({
    this.leave,
    this.overwrite,
    this.currBatch,
    this.prevBatch,
  });

  SyncDetails copyWith({
    bool? leave,
    bool? overwrite,
    String? currBatch,
    String? prevBatch,
  }) =>
      SyncDetails(
        leave: leave ?? this.leave,
        overwrite: overwrite ?? this.overwrite,
        currBatch: currBatch ?? this.currBatch,
      );
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

class Sync {
  final Room room;
  final SyncEvents events;
  final SyncDetails details;
  final Map<String, User> users;
  final Map<String, Receipt> readReceipts;

  const Sync({
    required this.room,
    this.events = const SyncEvents(),
    this.details = const SyncDetails(),
    this.readReceipts = const {},
    this.users = const {},
  });

  Sync copyWith({
    Room? room,
    SyncEvents? events,
    SyncDetails? details,
    Map<String, User>? users,
    Map<String, Receipt>? readReceipts,
  }) =>
      Sync(
        room: room ?? this.room,
        events: events ?? this.events,
        users: users ?? this.users,
        readReceipts: readReceipts ?? this.readReceipts,
      );

  ///
  /// Parse Details
  ///
  /// Parsed details about new timeline
  /// and batch information
  ///
  Sync parseDetails(Map<String, dynamic> json, String? lastSince) {
    bool? invite;
    bool? limited;
    bool? overwrite;
    int? totalMembers;

    // oldest batch in timeline
    String? lastBatch; // oldest batch in timeline
    // most recent batch from the last /sync
    String? prevBatch;
    // current batch - or current lastSince - in the timeline
    String? currBatch;

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

    return this.copyWith(
      room: room.copyWith(
        invite: invite,
        limited: limited,
        totalJoinedUsers: totalMembers,
        lastBatch: lastBatch ?? room.lastBatch ?? prevBatch,
        nextBatch: currBatch ?? lastSince,
      ),
      details: SyncDetails(
        overwrite: overwrite,
        currBatch: currBatch,
        prevBatch: prevBatch,
      ),
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
  Sync parseEvents(Map<String, dynamic> json) {
    final roomId = room.id;

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

      accountEvents = accountEventsRaw.map((event) => Event.fromMatrix(event, roomId: roomId)).toList();
    }

    if (json['ephemeral'] != null) {
      final List<dynamic> ephemeralEventsRaw = json['ephemeral']['events'];

      ephemeralEvents = ephemeralEventsRaw.map((event) => Event.fromMatrix(event, roomId: roomId)).toList();
    }

    if (json['timeline'] != null) {
      final List<dynamic> timelineEventsRaw = json['timeline']['events'];

      final List<Event> timelineEvents = List.from(
        timelineEventsRaw.map(
          (event) => Event.fromMatrix(
            event,
            roomId: roomId,
            currBatch: details.currBatch,
            prevBatch: room.prevBatch,
          ),
        ),
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

    return this.copyWith(
      events: SyncEvents(
        state: stateEvents,
        account: accountEvents,
        ephemeral: ephemeralEvents,
        redactions: redactionEvents,
        reactions: reactionEvents,
        messages: messageEvents,
      ),
    );
  }

  ///
  /// Parse Account Data
  ///
  /// Mostly used to assign is_direct
  Sync parseAccountData() {
    bool? isDirectNew;

    try {
      for (final event in events.account) {
        switch (event.type) {
          case 'm.direct':
            isDirectNew = true;
            break;
          default:
            break;
        }
      }
    } catch (error) {
      // ignore error processing
    }

    return this.copyWith(
      room: room.copyWith(
        direct: isDirectNew,
      ),
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
  Sync parseState(User currentUser) {
    bool? directNew;
    String? topicNew;
    int? lastUpdateNew;
    String? joinRuleNew;
    String? roomNameNew;
    String? avatarUriNew;
    bool? encryptionEnabledNew;

    int? leaveTimestamp;

    final usersAdd = <String, User>{};
    final Set<String> userIdsRemove = {};
    final Set<String> userIdsNew = Set.from(room.userIds);

    int namePriority = room.namePriority;

    for (final event in events.state) {
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
              roomNameNew = event.content['name'];
            }
            break;
          case 'm.room.topic':
            topicNew = event.content['topic'];
            break;

          case 'm.room.join_rules':
            joinRuleNew = event.content['join_rule'];
            break;

          case 'm.room.canonical_alias':
            if (namePriority > 2) {
              namePriority = 2;
              roomNameNew = event.content['alias'];
            }
            break;
          case 'm.room.aliases':
            if (namePriority > 3) {
              namePriority = 3;
              roomNameNew = event.content['aliases'][0];
            }
            break;
          case 'm.room.avatar':
            if (avatarUriNew == null) {
              avatarUriNew = event.content['url'];
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
              case 'join':
                if (event.stateKey == currentUser.userId) {
                  leaveTimestamp = null;
                }
                break;
              case 'ban':
              case 'leave':
                userIdsRemove.add(event.stateKey!);

                if (event.stateKey == currentUser.userId) {
                  leaveTimestamp = event.timestamp;
                }
                break;
              default:
                break;
            }

            break;
          case 'm.room.encryption':
            encryptionEnabledNew = true;
            break;
          case 'm.room.encrypted':
            break;
          default:
            break;
        }
      } catch (error) {
        console.error('[parseState] $error ${event.type}');
      }
    }

    final isDirect = directNew ?? room.direct;
    userIdsNew.addAll(usersAdd.keys);
    userIdsNew.removeWhere((id) => userIdsRemove.contains(id));

    // generate direct message room names without a explicitly set name
    if (isDirect) {
      // checks to make sure someone didn't name the room after the authed user
      final badRoomName = roomNameNew != null &&
          currentUser.userId != null &&
          (roomNameNew == currentUser.displayName || roomNameNew == currentUser.userId);

      final isNameDefault = namePriority == 4 && usersAdd.isNotEmpty;

      if (badRoomName || isNameDefault) {
        // Filter out number of non current users to show preview of total
        final otherUsers = usersAdd.values.where(
          (user) => user.userId != currentUser.userId,
        );

        if (otherUsers.isNotEmpty) {
          roomNameNew = selectDirectRoomName(currentUser, otherUsers, userIdsNew.length);
          avatarUriNew = selectDirectRoomAvatar(room, avatarUriNew, otherUsers);
        }
      }
    }

    return this.copyWith(
      details: details.copyWith(leave: leaveTimestamp != null),
      users: usersAdd.isNotEmpty ? usersAdd : null,
      room: room.copyWith(
        name: roomNameNew,
        topic: topicNew,
        direct: directNew,
        avatarUri: avatarUriNew,
        joinRule: joinRuleNew,
        namePriority: namePriority,
        lastUpdate: lastUpdateNew,
        encryptionEnabled: encryptionEnabledNew,
        // TODO: extract to pivot table for userIds associated by room
        userIds: userIdsNew.toList(),
      ),
    );
  }

  ///
  /// Parse Room Messages
  ///
  /// parses metadata for room from message metadata
  ///
  Sync parseMessages(List<String> currentMessageIds) {
    final messages = events.messages;

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

      if (DEBUG_MODE && DEBUG_PAYLOADS_MODE) {
        console.jsonDebug({
          'roomId': room.name,
          'latestMessage': latestMessage,
          'messagesTotal': messages.length,
          'lastUpdateNew': lastUpdateNew,
        });
      }

      // limited indicates need to fetch additional data for room timelines
      if (room.limited) {
        // TODO: potentially reimplement, but with batch tokens instead
        // Check to see if the new messages contain those existing in cache
        if (messages.isNotEmpty && currentMessageIds.isNotEmpty) {
          final messageKnown = currentMessageIds.firstWhereOrNull(
            (id) => id == messages[0].id,
          );

          // still limited if messages are all unknown / new
          limitedNew = messageKnown == null;
        }

        // will be null if no other events are available / batched in the timeline (also "end")
        if (details.prevBatch == null) {
          limitedNew = false;
        }

        // current previous batch is equal to the room's historical previous batch
        if (room.prevBatch == details.prevBatch) {
          limitedNew = false;
        }

        // if the previous batch is the last known batch, skip pulling it
        if (room.lastBatch == details.prevBatch) {
          limitedNew = false;
        }

        // if a last known batch hasn't been set (full sync is not complete) stop limited pulls
        if (room.lastBatch == null) {
          limitedNew = false;
        }

        // remove limited status regardless if overwrite enabled
        if (details.overwrite ?? false) {
          limitedNew = false;

          // pull if the room has no messages, but contains them later in the timeline
          if (messages.isEmpty && currentMessageIds.isEmpty) {
            limitedNew = true;
          }
        }
      }

      return this.copyWith(
        room: room.copyWith(
          limited: limitedNew,
          lastUpdate: lastUpdateNew,
          encryptionEnabled: hasEncrypted != null ? true : null,
        ),
      );
    } catch (error) {
      console.error('[parseMessages] $error');
      return this;
    }
  }

  ///
  /// Parse Ephemerals
  ///
  /// Appends ephemeral events (mostly read receipts) to a
  /// hashmap of eventIds linking them to users and timestamps
  ///
  Sync parseEphemerals(User currentUser) {
    bool userTypingUpdated = false;
    int lastReadUpdated = room.lastRead;
    List<String> usersTypingUpdated = room.usersTyping;

    final readReceiptsNew = <String, Receipt>{};

    try {
      for (final event in events.ephemeral) {
        switch (event.type) {
          case 'm.typing':
            final List<dynamic> usersTypingList = event.content['user_ids'];
            usersTypingUpdated = List<String>.from(usersTypingList);
            usersTypingUpdated.removeWhere(
              (user) => currentUser.userId == user,
            );
            userTypingUpdated = usersTypingUpdated.isNotEmpty;
            break;
          case 'm.receipt':
            final Map<String, dynamic> receiptEventIds = event.content;

            // Filter through every eventId to find receipts
            receiptEventIds.forEach((eventId, receipt) {
              // convert every m.read object to a map of userIds + timestamps for read
              final receiptsNew = Receipt.fromMatrix(eventId, receipt);

              // update the read receipts if that event has no reads yet
              if (!readReceiptsNew.containsKey(eventId)) {
                readReceiptsNew[eventId] = receiptsNew;
              } else {
                // otherwise, add the usersRead to the existing reads
                readReceiptsNew[eventId]!.userReads.addAll(receiptsNew.userReads);
              }
            });
            break;
          default:
            break;
        }
      }

      readReceiptsNew.forEach((key, value) {
        if (value.userReadsMapped!.containsKey(currentUser.userId)) {
          final int readTimestamp = value.userReadsMapped![currentUser.userId];

          if (readTimestamp > lastReadUpdated) {
            lastReadUpdated = readTimestamp;
          }
        }
      });
    } catch (error) {
      console.error('[parseEphemerals] $error');
    }

    return this.copyWith(
      readReceipts: readReceipts,
      room: room.copyWith(
        lastRead: lastReadUpdated,
        userTyping: userTypingUpdated,
        usersTyping: usersTypingUpdated,
      ),
    );
  }

  ///
  /// Parse Sync
  ///
  /// Not all events are needed to derive new information about the room
  ///
  /// Existing messages are used to check if a room has backfilled to a
  /// previously known position of chat / messages
  ///
  Sync parseSync({
    required User currentUser,
    required String? lastSince,
    required List<String> currentMessageIds,
    required Map<String, dynamic> json,
    bool ignoreMessageless = false,
  }) {
    final sync = this
        .parseDetails(
          json,
          lastSince,
        )
        .parseEvents(
          json,
        );

    if (ignoreMessageless && events.messages.isEmpty) {
      return sync;
    }

    if (DEBUG_MODE && room.limited) {
      console.jsonDebug({
        'from': '[parseSync]',
        'room': room.name,
        'limited': room.limited,
        'messages': events.messages.length,
        'lastBatch': room.lastBatch,
        'prevBatch': room.prevBatch,
      });
    }

    return sync
        .parseAccountData()
        .parseState(
          currentUser,
        )
        .parseMessages(
          currentMessageIds,
        )
        .parseEphemerals(
          currentUser,
        );
  }
}

///
/// Parse Sync
///
/// Parse Sync but not async
///
Sync parseSync({
  required Room currentRoom,
  required User currentUser,
  required String? lastSince,
  required List<String> currentMessageIds,
  required Map<String, dynamic> json,
  bool ignoreMessageless = false,
}) {
  return Sync(
    room: currentRoom,
  ).parseSync(
    json: json,
    lastSince: lastSince,
    currentUser: currentUser,
    currentMessageIds: currentMessageIds,
  );
}

///
/// Parse Sync (Mapped Params)
///
/// Parse Sync but compute safe
///
Future<Sync> parseSyncMapped(Map params) async {
  final json = params['json'] as Map<String, dynamic>;
  final Room currentRoom = params['room'];
  final User currentUser = params['currentUser'];
  final String? lastSince = params['lastSince'];
  final List<String> currentMessageIds = params['existingMessagesIds'];

  return Sync(
    room: currentRoom,
  ).parseSync(
    json: json,
    lastSince: lastSince,
    currentUser: currentUser,
    currentMessageIds: currentMessageIds,
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
  required Map<String, dynamic> json,
  required Room room,
  required User user,
  required String? lastSince,
  required List<String> currentMessageIds,
  ignoreMessageless = false,
}) async {
  return compute(parseSyncMapped, {
    'json': json,
    'room': room,
    'currentUser': user,
    'lastSince': lastSince,
    'existingMessagesIds': currentMessageIds,
  });
}
