// Dart imports:
import 'dart:collection';

// Package imports:
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:syphon/global/colours.dart';

// Project imports:
import 'package:syphon/global/libs/hive/type-ids.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/rooms/events/ephemeral/m.read/model.dart';
import 'package:syphon/store/rooms/events/model.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';

part 'model.g.dart';

class RoomPresets {
  static const private = 'private_chat';
  static const privateTrusted = 'trusted_private_chat';
  static const public = 'public_chat';
}

// Next Hive Field 30
@HiveType(typeId: RoomHiveId)
class Room {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String alias;
  @HiveField(3)
  final String homeserver;
  @HiveField(4)
  final String avatarUri;
  @HiveField(5)
  final String topic;
  @HiveField(29)
  final String joinRule; // "public", "knock", "invite", "private"

  @HiveField(28)
  final int namePriority;
  @HiveField(6)
  final bool direct;
  @HiveField(7)
  final bool syncing;
  @HiveField(8)
  final bool sending;
  @HiveField(9)
  final bool isDraftRoom;

  @HiveField(11)
  final String endHash; // end of last message fetch
  @HiveField(10)
  final String startHash; // start of last messages fetch (usually prev_batch)
  @HiveField(26)
  final String prevHash; // fromHash but from /sync only

  @HiveField(12)
  final int lastUpdate;
  @HiveField(13)
  final int totalJoinedUsers;

  @HiveField(14)
  final bool guestEnabled;
  @HiveField(15)
  final bool encryptionEnabled;
  @HiveField(16)
  final bool worldReadable;

  // Event lists and handlers
  @HiveField(17)
  final Message draft;

  // TODO: removed until state timeline work can be done
  // @HiveField(19)
  // final List<Event> state;

  @HiveField(20)
  final List<Message> messages;

  @HiveField(21)
  final List<Message> outbox;

  // Not cached
  final bool userTyping;
  final List<String> usersTyping;

  @HiveField(23)
  final int lastRead;

  @HiveField(24)
  final Map<String, ReadStatus> messageReads;

  @HiveField(25)
  final Map<String, User> users;

  @HiveField(27)
  final bool invite;

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

    return 'Group';
  }

  const Room({
    this.id,
    this.name = 'Chat',
    this.alias = '',
    this.homeserver,
    this.avatarUri,
    this.topic = '',
    this.joinRule = 'private',
    this.direct = false,
    this.syncing = false,
    this.sending = false,
    this.draft,
    this.users,
    this.outbox = const [],
    this.messages = const [],
    this.lastRead = 0,
    this.lastUpdate = 0,
    this.namePriority = 4,
    this.totalJoinedUsers = 0,
    this.guestEnabled = false,
    this.encryptionEnabled = false,
    this.worldReadable = false,
    this.userTyping = false,
    this.usersTyping = const [],
    this.isDraftRoom = false,
    this.endHash,
    this.startHash,
    this.prevHash,
    this.messageReads,
    this.invite = false,
  });

  Room copyWith({
    id,
    name,
    homeserver,
    avatar,
    avatarUri,
    topic,
    direct,
    syncing,
    sending,
    joinRule,
    lastRead,
    lastUpdate,
    namePriority,
    totalJoinedUsers,
    guestEnabled,
    encryptionEnabled,
    userTyping,
    usersTyping,
    isDraftRoom,
    draft,
    users,
    events,
    outbox,
    messages,
    messageReads,
    endHash,
    startHash,
    prevHash,
    invite,
    // state,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      alias: alias ?? this.alias,
      joinRule: joinRule ?? this.joinRule,
      avatarUri: avatarUri ?? this.avatarUri,
      homeserver: homeserver ?? this.homeserver,
      direct: direct ?? this.direct,
      draft: draft ?? this.draft,
      sending: sending ?? this.sending,
      syncing: syncing ?? this.syncing,
      lastRead: lastRead ?? this.lastRead,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      namePriority: namePriority ?? this.namePriority,
      totalJoinedUsers: totalJoinedUsers ?? this.totalJoinedUsers,
      guestEnabled: guestEnabled ?? this.guestEnabled,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      userTyping: userTyping ?? this.userTyping,
      usersTyping: usersTyping ?? this.usersTyping,
      isDraftRoom: isDraftRoom ?? this.isDraftRoom,
      outbox: outbox ?? this.outbox,
      messages: messages ?? this.messages,
      users: users ?? this.users,
      messageReads: messageReads ?? this.messageReads,
      endHash: endHash ?? this.endHash,
      startHash: startHash ?? this.startHash,
      prevHash: prevHash, // TODO: may always need a prev hash?
      invite: invite ?? this.invite,
      // state: state ?? this.state,
    );
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    try {
      return Room(
        id: json['room_id'],
        name: json['name'],
        alias: json['canonical_alias'],
        homeserver: (json['room_id'] as String).split(':')[1],
        topic: json['topic'],
        avatarUri: json['avatar_url'],
        totalJoinedUsers: json['num_joined_members'],
        guestEnabled: json['guest_can_join'],
        worldReadable: json['world_readable'],
        syncing: false,
      );
    } catch (error) {
      return Room();
    }
  }

  Room fromSync({
    User currentUser,
    String lastSince,
    Map<String, dynamic> json,
  }) {
    String endHash;
    String prevHash = this.prevHash;
    bool invite;

    List<Event> stateEvents = [];
    List<Event> ephemeralEvents = [];
    List<Message> messageEvents = [];
    List<Event> accountEvents = [];

    // Find state only updates
    if (json['state'] != null) {
      final List<dynamic> stateEventsRaw = json['state']['events'];

      stateEvents =
          stateEventsRaw.map((event) => Event.fromJson(event)).toList();
    }

    if (json['invite_state'] != null) {
      final List<dynamic> stateEventsRaw = json['invite_state']['events'];

      stateEvents =
          stateEventsRaw.map((event) => Event.fromJson(event)).toList();
      invite = true;
    }

    // Find state and message updates from timeline
    // Encryption events are not transfered in the state section of /sync
    if (json['timeline'] != null) {
      endHash = json['timeline']['end_batch'];
      prevHash = json['timeline']['prev_batch'];

      final List<dynamic> timelineEventsRaw = json['timeline']['events'];

      final List<Event> timelineEvents = List.from(
        timelineEventsRaw.map((event) => Event.fromJson(event)),
      );

      // TODO: make this more functional, need to split into two lists on type
      for (int i = 0; i < timelineEvents.length; i++) {
        final event = timelineEvents[i];

        if (event.type == EventTypes.message ||
            event.type == EventTypes.encrypted) {
          messageEvents.add(Message.fromEvent(event));
        } else {
          stateEvents.add(event);
        }
      }
    }

    if (json['ephemeral'] != null) {
      final List<dynamic> ephemeralEventsRaw = json['ephemeral']['events'];

      ephemeralEvents =
          ephemeralEventsRaw.map((event) => Event.fromJson(event)).toList();
    }

    if (json['account_data'] != null) {
      final List<dynamic> accountEventsRaw = json['account_data']['events'];

      accountEvents =
          accountEventsRaw.map((event) => Event.fromJson(event)).toList();
    }

    return this
        .fromAccountData(
          accountEvents,
        )
        .fromStateEvents(
          stateEvents,
          invite: invite,
          currentUser: currentUser,
        )
        .fromMessageEvents(
          messageEvents,
          endHash: endHash,
          prevHash: prevHash,
          startHash: lastSince,
        )
        .fromEphemeralEvents(
          ephemeralEvents,
          currentUser: currentUser,
        );
  }

  /**
   * 
   * fromAccountData
   * 
   * Mostly used to assign is_direct 
   */
  Room fromAccountData(
    List<Event> accountDataEvents,
  ) {
    dynamic isDirect;
    try {
      accountDataEvents.forEach((event) {
        switch (event.type) {
          case 'm.direct':
            isDirect = true;
            break;
          default:
            break;
        }
      });
    } catch (error) {}

    return this.copyWith(
      direct: isDirect ?? this.direct,
    );
  }

  /**
   * 
   * Find details of room based on state events
   * follows spec naming priority and thumbnail downloading
   */
  Room fromStateEvents(
    List<Event> stateEvents, {
    bool invite,
    User currentUser,
  }) {
    String name;
    String avatarUri;
    String topic;
    String joinRule;
    bool encryptionEnabled;
    bool direct = this.direct;
    int lastUpdate = this.lastUpdate;
    int namePriority = this.namePriority != 4 ? this.namePriority : 4;

    Map<String, User> users = this.users ?? Map<String, User>();

    // room state event filter
    try {
      stateEvents.forEach((event) {
        final timestamp = event.timestamp ?? 0;
        lastUpdate = timestamp > lastUpdate ? event.timestamp : lastUpdate;

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
            debugPrint('[Room.fromStateEvents] $joinRule');
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
            final avatarFile = event.content['thumbnail_file'];
            if (avatarFile == null) {
              avatarUri = event.content['url'];
            }
            break;

          case 'm.room.member':
            final displayName = event.content['displayname'];
            final memberAvatarUri = event.content['avatar_url'];

            direct = direct ?? event.content['is_direct'];

            // Cache user to rooms user cache if not present
            if (!users.containsKey(event.sender)) {
              users[event.sender] = User(
                userId: event.sender,
                displayName: displayName,
                avatarUri: memberAvatarUri,
              );
            }

            // likely an invite room
            // attempt to show a name from whoever sent membership events
            // if nothing else takes priority
            if (namePriority == 4 && event.sender != currentUser.userId) {
              if (displayName == null) {
                name = trimAlias(event.sender);
                avatarUri = memberAvatarUri;
              } else {
                name = displayName;
                avatarUri = memberAvatarUri;
              }
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
      });
    } catch (error) {}

    // direct room naming check
    try {
      final badRoomName =
          name == currentUser.displayName || name == currentUser.userId;

      // what happens if you name a direct chat after the
      // person you're sending it to? bad stuff, this tries
      // to force the senders name on the room just in case
      if (namePriority != 0 && users.isNotEmpty && (direct || badRoomName)) {
        namePriority = 0;

        // Filter out number of non current users to show preview of total and who

        final nonCurrentUsers = users.values.where(
          (user) =>
              user.displayName != currentUser.displayName &&
              user.userId != currentUser.userId,
        );

        final hasMultipleUsers =
            nonCurrentUsers.isNotEmpty && nonCurrentUsers.length > 1;
        final shownUser = users.values.elementAt(0);

        // set name and avi to first non user or that + total others
        name = hasMultipleUsers
            ? '${shownUser.displayName} and ${users.values.length - 1}'
            : shownUser.displayName;
        avatarUri = shownUser.avatarUri;
      }
    } catch (error) {}

    return this.copyWith(
      name: name ?? this.name ?? Strings.labelRoomNameDefault,
      topic: topic ?? this.topic,
      users: users ?? this.users,
      direct: direct ?? this.direct,
      avatarUri: avatarUri ?? this.avatarUri,
      joinRule: joinRule ?? this.joinRule,
      lastUpdate: lastUpdate > 0 ? lastUpdate : this.lastUpdate,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      namePriority: namePriority,
      invite: invite ?? this.invite,
    );
  }

  /**
   * fromMessageEvents
   * 
   * Update room based on messages events, many
   * message events have side effects on room data
   * outside displaying messages
   */
  Room fromMessageEvents(
    List<Message> messageEvents, {
    String endHash, // oldest hash in timeline
    String prevHash, // previously fetched hash
    String startHash,
  }) {
    try {
      int lastUpdate = this.lastUpdate;

      List<Message> newMessages = messageEvents ?? [];
      List<Message> outbox = List<Message>.from(this.outbox ?? []);
      List<Message> existingMessages = List<Message>.from(this.messages ?? []);

      // Converting only message events
      final hasEncrypted = newMessages.firstWhere(
        (msg) => msg.type == EventTypes.encrypted,
        orElse: () => null,
      );

      // See if the newest message has a greater timestamp
      if (newMessages.isNotEmpty && lastUpdate < newMessages[0].timestamp) {
        lastUpdate = newMessages[0].timestamp;
      }

      // Combine current and existing messages on unique ids
      existingMessages.addAll(newMessages);
      final messagesMap = HashMap.fromIterable(
        existingMessages,
        key: (message) => message.id,
        value: (message) => message,
      );

      // Remove outboxed messages
      outbox.removeWhere(
        (message) => messagesMap.containsKey(message.id),
      );

      // Filter to find startTime and endTime
      final allMessages = List<Message>.from(messagesMap.values);

      return this.copyWith(
        outbox: outbox,
        messages: allMessages,
        encryptionEnabled: this.encryptionEnabled || hasEncrypted != null,
        lastUpdate: lastUpdate ?? this.lastUpdate,
        // hash of last batch of messages in timeline
        endHash: endHash ?? this.endHash ?? prevHash,
        // hash of the latest batch messages in timeline
        startHash: startHash ?? this.startHash,
        // most recent previous batch from the last /sync
        prevHash: prevHash,
      );
    } catch (error) {
      return this;
    }
  }

  /**
   * Appends ephemeral events (mostly read receipts) to a
   * hashmap of eventIds linking them to users and timestamps
   */
  Room fromEphemeralEvents(
    List<Event> events, {
    User currentUser,
  }) {
    bool userTyping = false;
    List<String> usersTyping = this.usersTyping;

    int latestRead = this.lastRead;
    var messageReads = this.messageReads != null
        ? Map<String, ReadStatus>.from(this.messageReads)
        : Map<String, ReadStatus>();

    try {
      events.forEach((event) {
        switch (event.type) {
          case 'm.typing':
            final List<dynamic> usersTypingList = event.content['user_ids'];
            usersTyping = List<String>.from(usersTypingList);
            usersTyping.removeWhere(
              (user) => currentUser.userId == user,
            );
            userTyping = usersTyping.length > 0;
            break;
          case 'm.receipt':
            final Map<String, dynamic> receiptEventIds = event.content;

            // Filter through every eventId to find receipts
            receiptEventIds.forEach((key, receipt) {
              // convert every m.read object to a map of userIds + timestamps for read
              final newReadStatuses = ReadStatus.fromReceipt(receipt);

              // // Set a new timestamp for the latest read message if it exceeds the current
              latestRead = latestRead < newReadStatuses.latestRead
                  ? newReadStatuses.latestRead
                  : latestRead;

              // update the eventId if that event already has reads
              if (!messageReads.containsKey(key)) {
                messageReads[key] = newReadStatuses;
              } else {
                // otherwise, add the usersRead to the existing reads
                messageReads[key].userReads.addAll(newReadStatuses.userReads);
              }
            });
            break;
          default:
            break;
        }
      });
    } catch (error) {}

    return this.copyWith(
      userTyping: userTyping,
      usersTyping: usersTyping,
      messageReads: messageReads,
      lastRead: latestRead,
    );
  }
}
