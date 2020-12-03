// Dart imports:
import 'dart:collection';

// Package imports:
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

// Project imports:
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/rooms/events/ephemeral/m.read/model.dart';
import 'package:syphon/store/rooms/events/model.dart';
import 'package:syphon/store/user/model.dart';

part 'model.g.dart';

class RoomPresets {
  static const private = 'private_chat';
  static const privateTrusted = 'trusted_private_chat';
  static const public = 'public_chat';
}

@JsonSerializable()
class Room {
  final String id;
  final String name;
  final String alias;
  final String homeserver;
  final String avatarUri;
  final String topic;
  final String joinRule; // "public", "knock", "invite", "private"

  final int namePriority;
  final int lastRead;
  final bool direct;
  final bool syncing;
  final bool sending;
  final bool isDraftRoom;
  final bool invite;
  final bool guestEnabled;
  final bool encryptionEnabled;
  final bool worldReadable;

  final String lastHash; // oldest hash in timeline
  final String prevHash; // most recent prev_batch (not the lastHash)
  final String nextHash; // most recent next_batch

  final int lastUpdate;
  final int totalJoinedUsers;

  // Event lists and handlers
  final Message draft;

  // Associated user ids
  final List<String> userIds;

  // TODO: removed until state timeline work can be done
  // final List<Event> state;
  final List<Message> messages;
  final List<Message> outbox;

  final Map<String, ReadStatus> messageReads;

  @JsonKey(ignore: true)
  final Map<String, User> users;

  @JsonKey(ignore: true)
  final bool userTyping;

  @JsonKey(ignore: true)
  final List<String> usersTyping;

  @JsonKey(ignore: true)
  final bool limited;

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
    this.id,
    this.name = 'Empty Chat',
    this.alias = '',
    this.homeserver,
    this.avatarUri,
    this.topic = '',
    this.joinRule = 'private',
    this.invite = false,
    this.direct = false,
    this.syncing = false,
    this.sending = false,
    this.limited = false,
    this.draft,
    this.users,
    this.userIds = const [],
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
    this.lastHash,
    this.nextHash,
    this.prevHash,
    this.messageReads,
  });

  Room copyWith({
    id,
    name,
    homeserver,
    avatar,
    avatarUri,
    topic,
    invite,
    direct,
    limited,
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
    userIds,
    events,
    outbox,
    messages,
    messageReads,
    lastHash,
    prevHash,
    nextHash,
    // state,
  }) =>
      Room(
        id: id ?? this.id,
        name: name ?? this.name,
        alias: alias ?? this.alias,
        topic: topic ?? this.topic,
        joinRule: joinRule ?? this.joinRule,
        avatarUri: avatarUri ?? this.avatarUri,
        homeserver: homeserver ?? this.homeserver,
        draft: draft ?? this.draft,
        invite: invite ?? this.invite,
        direct: direct ?? this.direct,
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
        isDraftRoom: isDraftRoom ?? this.isDraftRoom,
        outbox: outbox ?? this.outbox,
        messages: messages ?? this.messages,
        users: users ?? this.users,
        userIds: userIds ?? this.userIds,
        messageReads: messageReads ?? this.messageReads,
        lastHash: lastHash ?? this.lastHash,
        prevHash: prevHash ?? this.prevHash,
        nextHash: nextHash ?? this.nextHash,
        // state: state ?? this.state,
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
    bool invite;
    bool limited;
    String lastHash;
    String prevHash = this.prevHash;

    List<Event> stateEvents = [];
    List<Event> ephemeralEvents = [];
    List<Message> messageEvents = [];
    List<Event> accountEvents = [];

    // Find state only updates
    if (json['state'] != null) {
      final List<dynamic> stateEventsRaw = json['state']['events'];

      stateEvents =
          stateEventsRaw.map((event) => Event.fromMatrix(event)).toList();
    }

    if (json['invite_state'] != null) {
      final List<dynamic> stateEventsRaw = json['invite_state']['events'];

      stateEvents =
          stateEventsRaw.map((event) => Event.fromMatrix(event)).toList();
      invite = true;
    }

    // Find state and message updates from timeline
    // Encryption events are not transfered in the state section of /sync
    if (json['timeline'] != null) {
      limited = json['timeline']['limited'];
      lastHash = json['timeline']['last_hash'];
      prevHash = json['timeline']['prev_batch'];

      if (limited != null) {
        debugPrint(
          '[fromSync] LIMITED ${limited} ${lastHash} ${prevHash}',
        );
      }

      final List<dynamic> timelineEventsRaw = json['timeline']['events'];

      final List<Event> timelineEvents = List.from(
        timelineEventsRaw.map((event) => Event.fromMatrix(event)),
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
          ephemeralEventsRaw.map((event) => Event.fromMatrix(event)).toList();
    }

    if (json['account_data'] != null) {
      final List<dynamic> accountEventsRaw = json['account_data']['events'];

      accountEvents =
          accountEventsRaw.map((event) => Event.fromMatrix(event)).toList();
    }

    return this
        .fromAccountData(
          accountEvents,
        )
        .fromStateEvents(
          invite: invite,
          limited: limited,
          events: stateEvents,
          currentUser: currentUser,
        )
        .fromMessageEvents(
          events: messageEvents,
          lastHash: lastHash,
          prevHash: prevHash,
          nextHash: lastSince,
        )
        .fromEphemeralEvents(
          events: ephemeralEvents,
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
  Room fromStateEvents({
    bool invite,
    bool limited,
    User currentUser,
    List<Event> events,
  }) {
    String name;
    String avatarUri;
    String topic;
    String joinRule;
    bool encryptionEnabled;
    bool direct = this.direct ?? false;
    int lastUpdate = this.lastUpdate;
    int namePriority = this.namePriority != 4 ? this.namePriority : 4;
    Map<String, User> users = this.users ?? Map<String, User>();

    try {
      events.forEach((event) {
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

            direct = !direct ? event.content['is_direct'] ?? false : direct;

            // Cache user to rooms user cache if not present
            if (!users.containsKey(event.sender)) {
              users[event.sender] = User(
                userId: event.sender,
                displayName: displayName,
                avatarUri: memberAvatarUri,
              );
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
    } catch (error) {
      debugPrint('[Room.fromStateEvents] ${error}');
    }

    try {
      // checks to make sure someone didn't name the room after the authed user
      final badRoomName =
          name == currentUser.displayName || name == currentUser.userId;

      // no name room check
      if ((namePriority > 3 && users.isNotEmpty && direct) || badRoomName) {
        // Filter out number of non current users to show preview of total
        final otherUsers = users.values.where(
          (user) =>
              user.userId != currentUser.userId &&
              user.displayName != currentUser.displayName,
        );

        if (otherUsers.isNotEmpty) {
          // check naming options when direct/group without room name
          final shownUser = otherUsers.elementAt(0);
          final hasMultipleUsers = otherUsers.length > 1;

          // set name and avi to first non user or that + total others
          name = hasMultipleUsers
              ? '${shownUser.displayName} and ${users.values.length - 1}'
              : shownUser.displayName;

          // set avatar if one has not been assigned
          if (avatarUri == null &&
              this.avatarUri == null &&
              otherUsers.length == 1) {
            avatarUri = shownUser.avatarUri;
          }
        }
      }
    } catch (error) {}

    return this.copyWith(
      name: name ?? this.name ?? Strings.labelRoomNameDefault,
      topic: topic ?? this.topic,
      users: users ?? this.users,
      userIds: users.keys.toList(),
      direct: direct ?? this.direct,
      invite: invite ?? this.invite,
      limited: limited ?? this.limited,
      avatarUri: avatarUri ?? this.avatarUri,
      joinRule: joinRule ?? this.joinRule,
      lastUpdate: lastUpdate > 0 ? lastUpdate : this.lastUpdate,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      namePriority: namePriority,
    );
  }

  /**
   * fromMessageEvents
   * 
   * Update room based on messages events, many
   * message events have side effects on room data
   * outside displaying messages
   */
  Room fromMessageEvents({
    List<Message> events,
    String lastHash,
    String prevHash, // previously fetched hash
    String nextHash,
  }) {
    try {
      bool limited;
      int lastUpdate = this.lastUpdate;
      List<Message> messagesNew = events ?? [];
      List<Message> outbox = List<Message>.from(this.outbox ?? []);
      List<Message> messagesExisting = List<Message>.from(this.messages ?? []);

      // Converting only message events
      final hasEncrypted = messagesNew.firstWhere(
        (msg) => msg.type == EventTypes.encrypted,
        orElse: () => null,
      );

      // See if the newest message has a greater timestamp
      if (messagesNew.isNotEmpty && lastUpdate < messagesNew[0].timestamp) {
        lastUpdate = messagesNew[0].timestamp;
      }

      // limited indicates need to fetch additional data for room timelines
      if (this.limited) {
        // Check to see if the new messages contain those existing in cache
        if (messagesNew.isNotEmpty && messagesExisting.isNotEmpty) {
          final messageLatest = messagesExisting.firstWhere(
            (msg) => msg.id == messagesNew[0].id,
            orElse: () => null,
          );
          // Set limited to false if they now exist
          limited = messageLatest != null;
        }

        // Set limited to false false if
        // - the oldest hash (lastHash) is non-existant
        // - the previous hash (most recent) is non-existant
        // - the oldest hash equals the previously fetched hash
        if (this.lastHash == null ||
            this.prevHash == null ||
            this.lastHash == this.prevHash) {
          limited = false;
        }
      }

      // Combine current and existing messages on unique ids
      messagesExisting.addAll(messagesNew);
      final messagesMap = HashMap.fromIterable(
        messagesExisting,
        key: (message) => message.id,
        value: (message) => message,
      );

      // Remove outboxed messages
      outbox.removeWhere(
        (message) => messagesMap.containsKey(message.id),
      );

      // Filter to find startTime and endTime
      final messagesAll = List<Message>.from(messagesMap.values);

      // Save values to room
      return this.copyWith(
        outbox: outbox,
        messages: messagesAll,
        limited: limited ?? this.limited,
        encryptionEnabled: this.encryptionEnabled || hasEncrypted != null,
        lastUpdate: lastUpdate ?? this.lastUpdate,
        // oldest hash in the timeline
        lastHash: lastHash ?? this.lastHash ?? prevHash,
        // most recent prev_batch from the last /sync
        prevHash: prevHash ?? this.prevHash,
        // next hash in the timeline
        nextHash: nextHash ?? this.nextHash,
      );
    } catch (error) {
      debugPrint('[fromMessageEvents] $error');
      return this;
    }
  }

  /**
   * Appends ephemeral events (mostly read receipts) to a
   * hashmap of eventIds linking them to users and timestamps
   */
  Room fromEphemeralEvents({
    List<Event> events,
    User currentUser,
  }) {
    bool userTyping = false;
    List<String> usersTyping = this.usersTyping;

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

            // TODO: figure out how to pull what messages have been read from read recepts
            // // Set a new timestamp for the latest read message if it exceeds the current
            // latestRead = latestRead < newReadStatuses.latestRead
            //     ? newReadStatuses.latestRead
            //     : latestRead;

            // Filter through every eventId to find receipts
            receiptEventIds.forEach((key, receipt) {
              // convert every m.read object to a map of userIds + timestamps for read
              final newReadStatuses = ReadStatus.fromReceipt(receipt);

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
    );
  }
}
