import 'dart:collection';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:drift/drift.dart' as drift;
import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/storage/drift/database.dart';
import 'package:syphon/store/events/ephemeral/m.read/model.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/redaction/model.dart';
import 'package:syphon/store/settings/chat-settings/model.dart';
import 'package:syphon/store/sync/parsers.dart';
import 'package:syphon/store/user/model.dart';

part 'model.g.dart';

class RoomPresets {
  static const private = 'private_chat';
  static const privateTrusted = 'trusted_private_chat';
  static const public = 'public_chat';
}

@JsonSerializable()
class Room implements drift.Insertable<Room> {
  final String id;
  final String? name;
  final String? alias;
  final String? homeserver;
  final String? avatarUri;
  final String? topic;
  final String? joinRule; // "public", "knock", "invite", "private"

  final bool drafting;
  final bool direct;
  final bool sending;
  final bool invite;
  final bool guestEnabled;
  final bool encryptionEnabled;
  final bool worldReadable;
  final bool hidden;
  final bool archived;

  final String? lastBatch; // oldest batch in timeline
  final String? prevBatch; // most recent prev_batch (not the lastBatch)
  final String? nextBatch; // most recent next_batch

  final int lastRead;
  final int lastUpdate;
  final int totalJoinedUsers;
  final int namePriority;

  // Event lists and handlers
  final Message? draft;
  final Message? reply;

  // Associated user ids
  final List<String> userIds;
  final List<String> messageIds;

  @JsonKey(ignore: true)
  final List<Message> outbox;

  // TODO: removed until state timeline work can be done
  @JsonKey(ignore: true)
  final List<Event>? state;

  @JsonKey(ignore: true)
  final Map<String, ReadReceipt>? readReceiptsTEMP;

  @JsonKey(ignore: true)
  final Map<String, User> usersTEMP;

  @JsonKey(ignore: true)
  final bool userTyping;

  @JsonKey(ignore: true)
  final List<String> usersTyping;

  @JsonKey(ignore: true)
  final bool limited;

  @JsonKey(ignore: true)
  final bool syncing;

  @JsonKey(ignore: true)
  String get type {
    if (joinRule == 'public' || worldReadable) {
      return 'public';
    }

    if (direct) {
      return 'direct';
    }

    if (invite) {
      return 'invite';
    }

    return 'group';
  }

  const Room({
    required this.id,
    this.name = 'Empty Chat',
    this.alias = '',
    this.homeserver,
    this.avatarUri,
    this.topic = '',
    this.joinRule = 'private',
    this.drafting = false,
    this.invite = false,
    this.direct = false,
    this.syncing = false,
    this.sending = false,
    this.limited = false,
    this.hidden = false,
    this.archived = false,
    this.draft,
    this.reply,
    this.userIds = const [],
    this.outbox = const [],
    this.usersTEMP = const {},
    this.messageIds = const [],
    this.lastRead = 0,
    this.lastUpdate = 0,
    this.namePriority = 4,
    this.totalJoinedUsers = 0,
    this.guestEnabled = false,
    this.encryptionEnabled = false,
    this.worldReadable = false,
    this.userTyping = false,
    this.usersTyping = const [],
    this.lastBatch,
    this.nextBatch,
    this.prevBatch,
    this.readReceiptsTEMP,
    this.state,
  });

  Room copyWith({
    String? id,
    String? name,
    String? homeserver,
    String? avatarUri,
    String? topic,
    bool? invite,
    bool? direct,
    bool? limited,
    bool? syncing,
    bool? sending,
    bool? drafting,
    bool? hidden,
    bool? archived,
    joinRule,
    int? lastRead,
    int? lastUpdate,
    int? namePriority,
    int? totalJoinedUsers,
    guestEnabled,
    encryptionEnabled,
    userTyping,
    usersTyping,
    draft,
    reply,
    List<String>? userIds,
    events,
    List<String>? messageIds,
    List<Message>? outbox,
    Map<String, User>? usersTEMP,
    Map<String, ReadReceipt>? readReceiptsTEMP,
    String? lastBatch,
    String? prevBatch,
    String? nextBatch,
    state,
  }) =>
      Room(
        id: id ?? this.id,
        name: name ?? this.name,
        alias: alias ?? alias,
        topic: topic ?? this.topic,
        joinRule: joinRule ?? this.joinRule,
        avatarUri: avatarUri ?? this.avatarUri,
        homeserver: homeserver ?? this.homeserver,
        drafting: drafting ?? this.drafting,
        invite: invite ?? this.invite,
        direct: direct ?? this.direct,
        hidden: hidden ?? this.hidden,
        archived: archived ?? this.archived,
        sending: sending ?? this.sending,
        syncing: syncing ?? this.syncing,
        limited: limited ?? this.limited,
        lastRead: lastRead ?? this.lastRead,
        lastUpdate: lastUpdate ?? this.lastUpdate,
        namePriority: namePriority ?? this.namePriority,
        totalJoinedUsers: totalJoinedUsers ?? this.totalJoinedUsers,
        guestEnabled: guestEnabled ?? this.guestEnabled,
        encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
        userTyping: userTyping ?? this.userTyping,
        usersTyping: usersTyping ?? this.usersTyping,
        draft: draft ?? this.draft,
        reply: reply == Null ? null : reply ?? this.reply,
        state: state ?? this.state,
        outbox: outbox ?? this.outbox,
        userIds: userIds ?? this.userIds,
        messageIds: messageIds ?? this.messageIds,
        lastBatch: lastBatch ?? this.lastBatch,
        prevBatch: prevBatch ?? this.prevBatch,
        nextBatch: nextBatch ?? this.nextBatch,
        usersTEMP: usersTEMP ?? this.usersTEMP,
        readReceiptsTEMP: readReceiptsTEMP ?? this.readReceiptsTEMP,
      );

  Map<String, dynamic> toJson() => _$RoomToJson(this);
  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
  factory Room.fromMatrix(Map<String, dynamic> json) {
    try {
      return Room(
        id: json['room_id'],
        name: json['name'],
        alias: json['canonical_alias'],
        homeserver: (json['room_id'] as String).split(':')[1],
        topic: json['topic'],
        avatarUri: json['avatar_url'],
        totalJoinedUsers: json['num_joined_members'] ?? 0,
        guestEnabled: json['guest_can_join'],
        worldReadable: json['world_readable'],
        syncing: false,
      );
    } catch (error) {
      return Room(id: json['room_id']);
    }
  }

  Room fromEvents({
    required User currentUser,
    required SyncEvents events,
    bool? invite,
    bool? limited,
    String? lastBatch,
    String? prevBatch,
    String? lastSince,
    List<String> existingIds = const [],
  }) {
    return fromAccountData(events.account)
        .fromStateEvents(
          invite: invite,
          limited: limited,
          currentUser: currentUser,
          events: events.state,
        )
        .fromMessageEvents(
          lastBatch: lastBatch,
          nextBatch: lastSince,
          prevBatch: prevBatch,
          messages: events.messages,
          existingIds: existingIds,
        )
        .fromEphemeralEvents(
          currentUser: currentUser,
          events: events.ephemeral,
        );
  }

  ///
  /// fromAccountData
  ///
  /// Mostly used to assign is_direct
  Room fromAccountData(List<Event> accountDataEvents) {
    dynamic isDirect;
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
    } catch (error) {}

    return copyWith(
      direct: isDirect ?? direct,
    );
  }

  ///
  /// Find details of room based on state events
  /// follows spec naming priority and thumbnail downloading
  Room fromStateEvents({
    required User currentUser,
    required List<Event> events,
    bool? invite,
    bool? limited,
    List<Reaction>? reactions,
    List<Redaction>? redactions,
    LastUpdateType lastUpdateType = LastUpdateType.Message,
  }) {
    String? name;
    String? avatarUri;
    String? topic;
    String? joinRule;
    bool? encryptionEnabled;
    bool direct = this.direct;
    int? lastUpdate = this.lastUpdate;
    int namePriority = this.namePriority;

    final Map<String, User> usersAdd = Map.from(usersTEMP);
    Set<String> userIds = Set<String>.from(this.userIds);
    final List<String> userIdsRemove = [];

    for (final event in events) {
      try {
        final timestamp = event.timestamp;
        if (lastUpdateType == LastUpdateType.State) {
          lastUpdate = timestamp > lastUpdate! ? timestamp : lastUpdate;
        }

        switch (event.type) {
          case 'm.room.name':
            if (namePriority > 0) {
              namePriority = 1;
              name = event.content['name'];
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
              name = event.content['alias'];
            }
            break;
          case 'm.room.aliases':
            if (namePriority > 3) {
              namePriority = 3;
              name = event.content['aliases'][0];
            }
            break;
          case 'm.room.avatar':
            if (avatarUri == null) {
              avatarUri = event.content['url'];
            }
            break;

          case 'm.room.member':
            final displayName = event.content['displayname'];
            final memberAvatarUri = event.content['avatar_url'];
            final membership = event.content['membership'];

            direct = !direct ? event.content['is_direct'] ?? false : direct;

            // Cache user to rooms user cache if not present
            if (!usersAdd.containsKey(event.stateKey)) {
              usersAdd[event.stateKey!] = User(
                userId: event.stateKey,
                displayName: displayName,
                avatarUri: memberAvatarUri,
              );
            }

            if (membership == 'leave') {
              userIdsRemove.add(event.stateKey!);
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
        printError('[Room.fromStateEvents] $error ${event.type}');
      }
    }

    userIds = userIds..addAll(usersAdd.keys);
    userIds = userIds..removeWhere((id) => userIdsRemove.contains(id));

    try {
      // checks to make sure someone didn't name the room after the authed user
      final badRoomName = name == currentUser.displayName || name == currentUser.userId;

      // no name room check
      if ((namePriority > 3 && usersAdd.isNotEmpty && direct) || badRoomName) {
        // Filter out number of non current users to show preview of total
        final otherUsers = usersAdd.values.where(
          (user) => user.userId != currentUser.userId,
        );

        if (otherUsers.isNotEmpty) {
          // check naming options when direct/group without room name
          final shownUser = otherUsers.elementAt(0);
          final hasMultipleUsers = otherUsers.length > 1;

          // set name and avi to first non user or that + total others
          name = shownUser.displayName;

          if (name == currentUser.displayName) {
            name = '${shownUser.displayName} (${shownUser.userId})';
          }

          if (hasMultipleUsers) {
            name = '${shownUser.displayName} and ${usersAdd.values.length - 1} others';
          }

          // set avatar if one has not been assigned
          if (avatarUri == null && this.avatarUri == null && otherUsers.length == 1) {
            avatarUri = shownUser.avatarUri;
          }
        }
      }
    } catch (error) {
      printError('[directRoomName] ${error.toString()}');
    }

    return copyWith(
      name: name ?? this.name ?? Strings.labelRoomNameDefault,
      topic: topic ?? this.topic,
      direct: direct,
      invite: invite ?? this.invite,
      limited: limited ?? this.limited,
      userIds: userIds.toList(),
      avatarUri: avatarUri ?? this.avatarUri,
      joinRule: joinRule ?? this.joinRule,
      lastUpdate: lastUpdate,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      namePriority: namePriority,
      usersTEMP: usersAdd,
    );
  }

  /// fromMessageEvents
  ///
  /// Update room based on messages events, many
  /// message events have side effects on room data
  /// outside displaying messages
  Room fromMessageEvents({
    List<Message> messages = const [],
    List<String> existingIds = const [],
    String? lastBatch,
    String? prevBatch, // previously fetched batch
    String? nextBatch,
  }) {
    try {
      bool? limited;
      int lastUpdate = this.lastUpdate;
      final messageIds = this.messageIds;
      final limitedCurrent = this.limited;

      // Converting only message events
      final hasEncrypted = messages.firstWhereOrNull(
        (msg) => msg.type == EventTypes.encrypted,
      );

      // See if the newest message has a greater timestamp
      final latestMessage = messages.firstWhereOrNull(
        (msg) => lastUpdate < msg.timestamp,
      );

      if (latestMessage != null) {
        lastUpdate = latestMessage.timestamp;
      }

      // limited indicates need to fetch additional data for room timelines
      if (limitedCurrent) {
        // TODO: deprecated - remove along with messageIds
        // TODO: potentially reimplement, but with batch tokens instead
        // TODO: consider also using another "existingIds" param instead to prevent
        // TODO: needing room to have some state value
        // Check to see if the new messages contain those existing in cache
        if (messages.isNotEmpty && messageIds.isNotEmpty) {
          final messageKnown = messageIds.firstWhereOrNull(
            (id) => id == messages[0].id,
          );

          // still limited if messages are all unknown / new
          limited = messageKnown == null;
        }

        // current previous batch is equal to the room's historical previous batch
        if (prevBatch == this.prevBatch) {
          limited = false;
        }

        // if the previous batch is the last known batch, skip pulling it
        if (prevBatch == this.lastBatch) {
          limited = false;
        }

        // will be null if no other events are available / batched in the timeline (also "end")
        if (prevBatch == null) {
          limited = false;
        }

        // if a last known batch hasn't been set (full sync is not complete) stop limited pulls
        if (this.lastBatch == null) {
          limited = false;
        }
      }

      // Combine current and existing messages on unique ids
      final messagesMap = HashMap.fromIterable(
        messages,
        key: (message) => message.id,
        value: (message) => message,
      );

      // save messages and unique message id updates
      final messageIdsNew = Set<String>.from(messagesMap.keys);
      final messageIdsAll = Set<String>.from(messageIds)..addAll(messageIdsNew);

      // Save values to room
      return copyWith(
        messageIds: messageIdsAll.toList(),
        limited: limited ?? this.limited,
        encryptionEnabled: encryptionEnabled || hasEncrypted != null,
        lastUpdate: lastUpdate,
        // oldest hash in the timeline
        lastBatch: lastBatch ?? this.lastBatch ?? prevBatch,
        // TODO: fetchMessages maks this temporarily misassigned
        // most recent prev_batch from the last /sync
        prevBatch: prevBatch ?? this.prevBatch,
        // next hash in the timeline
        nextBatch: nextBatch ?? nextBatch,
      );
    } catch (error) {
      printError('[fromMessageEvents] $error');
      return this;
    }
  }

  /// Appends ephemeral events (mostly read receipts) to a
  /// hashmap of eventIds linking them to users and timestamps
  Room fromEphemeralEvents({
    required List<Event> events,
    User? currentUser,
  }) {
    bool userTyping = false;
    List<String> usersTyping = this.usersTyping;
    final readReceipts = Map<String, ReadReceipt>.from(readReceiptsTEMP ?? {});

    try {
      for (final event in events) {
        switch (event.type) {
          case 'm.typing':
            final List<dynamic> usersTypingList = event.content['user_ids'];
            usersTyping = List<String>.from(usersTypingList);
            usersTyping.removeWhere(
              (user) => currentUser!.userId == user,
            );
            userTyping = usersTyping.isNotEmpty;
            break;
          case 'm.receipt':
            final Map<String, dynamic> receiptEventIds = event.content;

            // TODO: figure out how to pull what messages have been read from read recepts
            // // Set a new timestamp for the latest read message if it exceeds the current
            // latestRead = latestRead < newReadStatuses.latestRead
            //     ? newReadStatuses.latestRead
            //     : latestRead;

            // Filter through every eventId to find receipts
            receiptEventIds.forEach((key, receipt) {
              // convert every m.read object to a map of userIds + timestamps for read
              final readReceiptsNew = ReadReceipt.fromReceipt(receipt);

              // update the eventId if that event already has reads
              if (!readReceipts.containsKey(key)) {
                readReceipts[key] = readReceiptsNew;
              } else {
                // otherwise, add the usersRead to the existing reads
                readReceipts[key]!.userReads!.addAll(readReceiptsNew.userReads!);
              }
            });
            break;
          default:
            break;
        }
      }
    } catch (error) {}

    return copyWith(
      userTyping: userTyping,
      usersTyping: usersTyping,
      readReceiptsTEMP: readReceipts,
    );
  }

  // allows converting to message companion type for saving through drift
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    return RoomsCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      alias: drift.Value(alias),
      homeserver: drift.Value(homeserver),
      avatarUri: drift.Value(avatarUri),
      topic: drift.Value(topic),
      joinRule: drift.Value(joinRule),
      drafting: drift.Value(drafting),
      direct: drift.Value(direct),
      sending: drift.Value(sending),
      invite: drift.Value(invite),
      guestEnabled: drift.Value(guestEnabled),
      encryptionEnabled: drift.Value(encryptionEnabled),
      worldReadable: drift.Value(worldReadable),
      hidden: drift.Value(hidden),
      archived: drift.Value(archived),
      lastBatch: drift.Value(lastBatch),
      prevBatch: drift.Value(prevBatch),
      nextBatch: drift.Value(nextBatch),
      lastRead: drift.Value(lastRead),
      lastUpdate: drift.Value(lastUpdate),
      totalJoinedUsers: drift.Value(totalJoinedUsers),
      namePriority: drift.Value(namePriority),
      draft: drift.Value(draft),
      reply: drift.Value(reply),
      userIds: drift.Value(userIds),
      messageIds: drift.Value(messageIds),
    ).toColumns(nullToAbsent);
  }
}
