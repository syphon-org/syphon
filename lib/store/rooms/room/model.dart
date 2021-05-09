// Dart imports:
import 'dart:collection';

// Package imports:
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/global/print.dart';

// Project imports:
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/events/ephemeral/m.read/model.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/redaction/model.dart';
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

  final bool drafting;
  final bool direct;
  final bool sending;
  final bool invite;
  final bool guestEnabled;
  final bool encryptionEnabled;
  final bool worldReadable;
  final bool hidden;
  final bool archived;

  final String lastHash; // oldest hash in timeline
  final String prevHash; // most recent prev_batch (not the lastHash)
  final String nextHash; // most recent next_batch

  final int lastRead;
  final int lastUpdate;
  final int totalJoinedUsers;
  final int namePriority;

  // Event lists and handlers
  final Message draft;
  final Message reply;

  // Associated user ids
  final List<String> userIds;
  final List<String> messageIds;
  final List<String> reactionIds;
  final List<Message> outbox;

  // TODO: removed until state timeline work can be done
  @JsonKey(ignore: true)
  final List<Event> state;

  @JsonKey(ignore: true)
  final List<Reaction> reactions;

  @JsonKey(ignore: true)
  final List<Redaction> redactions;

  @JsonKey(ignore: true)
  final List<Message> messagesNew;

  @JsonKey(ignore: true)
  final Map<String, ReadReceipt> readReceipts;

  @JsonKey(ignore: true)
  final Map<String, User> usersNew;

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
    this.reply,
    this.userIds = const [],
    this.outbox = const [],
    this.usersNew = const {},
    this.reactions = const [],
    this.messagesNew = const [],
    this.messageIds = const [],
    this.reactionIds = const [],
    this.redactions = const [],
    this.lastRead = 0,
    this.lastUpdate = 0,
    this.namePriority = 4,
    this.totalJoinedUsers = 0,
    this.guestEnabled = false,
    this.encryptionEnabled = false,
    this.worldReadable = false,
    this.userTyping = false,
    this.usersTyping = const [],
    this.drafting = false,
    this.hidden = false,
    this.archived = false,
    this.lastHash,
    this.nextHash,
    this.prevHash,
    this.readReceipts,
    this.state,
  });

  Room copyWith({
    String id,
    String name,
    String homeserver,
    avatar,
    avatarUri,
    topic,
    invite,
    bool direct,
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
    draft,
    reply,
    drafting,
    hidden,
    archived,
    users,
    userIds,
    events,
    List<Message> outbox,
    List<Message> messagesNew,
    List<Event> reactions,
    List<String> messageIds,
    List<String> reactionIds,
    List<Redaction> redactions,
    Map<String, ReadReceipt> readReceipts,
    lastHash,
    prevHash,
    nextHash,
    state,
  }) =>
      Room(
        id: id ?? this.id,
        name: name ?? this.name,
        alias: alias ?? this.alias,
        topic: topic ?? this.topic,
        joinRule: joinRule ?? this.joinRule,
        avatarUri: avatarUri ?? this.avatarUri,
        homeserver: homeserver ?? this.homeserver,
        drafting: drafting ?? this.drafting ?? false,
        invite: invite ?? this.invite,
        direct: direct ?? this.direct,
        hidden: hidden ?? this.hidden ?? false,
        archived: archived ?? this.archived ?? false,
        sending: sending ?? this.sending ?? false,
        syncing: syncing ?? this.syncing ?? false,
        limited: limited ?? this.limited ?? false,
        lastRead: lastRead ?? this.lastRead,
        lastUpdate: lastUpdate ?? this.lastUpdate,
        namePriority: namePriority ?? this.namePriority,
        totalJoinedUsers: totalJoinedUsers ?? this.totalJoinedUsers,
        guestEnabled: guestEnabled ?? this.guestEnabled,
        encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
        userTyping: userTyping ?? this.userTyping,
        usersTyping: usersTyping ?? this.usersTyping,
        draft: draft ?? this.draft,
        reply: reply ?? this.reply,
        outbox: outbox ?? this.outbox,
        messageIds: messageIds ?? this.messageIds,
        messagesNew: messagesNew ?? this.messagesNew,
        reactions: reactions ?? this.reactions,
        redactions: redactions ?? this.redactions,
        usersNew: users ?? this.usersNew,
        userIds: userIds ?? this.userIds,
        readReceipts: readReceipts ?? this.readReceipts,
        lastHash: lastHash ?? this.lastHash,
        prevHash: prevHash ?? this.prevHash,
        nextHash: nextHash ?? this.nextHash,
        state: state ?? this.state,
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
    List<Event> accountEvents = [];
    List<Event> ephemeralEvents = [];
    List<Reaction> reactionEvents = [];
    List<Message> messageEvents = [];
    List<Redaction> redactionEvents = [];

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

    // Find state and message updates from timeline
    // Encryption events are not transfered in the state section of /sync
    if (json['timeline'] != null) {
      limited = json['timeline']['limited'];
      lastHash = json['timeline']['last_hash'];
      prevHash = json['timeline']['prev_batch'];

      if (limited != null) {
        printDebug(
          '[fromSync] ${this.id} limited ${limited} lastHash ${lastHash != null} prevHash ${prevHash != null}',
        );
      }

      final List<dynamic> timelineEventsRaw = json['timeline']['events'];

      final List<Event> timelineEvents = List.from(
        timelineEventsRaw.map((event) => Event.fromMatrix(event)),
      );

      for (Event event in timelineEvents) {
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

    return this
        .fromAccountData(
          accountEvents,
        )
        .fromStateEvents(
          invite: invite,
          limited: limited,
          events: stateEvents,
          currentUser: currentUser,
          reactions: reactionEvents,
          redactions: redactionEvents,
        )
        .fromMessageEvents(
          messages: messageEvents,
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
  Room fromAccountData(List<Event> accountDataEvents) {
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
    List<Reaction> reactions,
    List<Redaction> redactions,
  }) {
    String name;
    String avatarUri;
    String topic;
    String joinRule;
    bool encryptionEnabled;
    bool direct = this.direct ?? false;
    int lastUpdate = this.lastUpdate;
    int namePriority = this.namePriority != 4 ? this.namePriority : 4;

    var usersAdd = Map<String, User>.from(this.usersNew ?? {});
    var userIdsRemove = List<String>();

    Set<String> userIds = Set<String>.from(this.userIds ?? []);

    events.forEach((event) {
      try {
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
            final membership = event.content['membership'];

            direct = !direct ? event.content['is_direct'] ?? false : direct;

            // Cache user to rooms user cache if not present
            if (!usersAdd.containsKey(event.stateKey)) {
              usersAdd[event.stateKey] = User(
                userId: event.stateKey,
                displayName: displayName,
                avatarUri: memberAvatarUri,
              );
            }

            if (membership == 'leave') {
              userIdsRemove.add(event.stateKey);
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
        debugPrint('[Room.fromStateEvents] ${error} ${event.type}');
      }
    });

    userIds = userIds..addAll(usersAdd.keys ?? []);
    userIds = userIds..removeWhere((id) => userIdsRemove.contains(id));

    try {
      // checks to make sure someone didn't name the room after the authed user
      final badRoomName =
          name == currentUser.displayName || name == currentUser.userId;

      // no name room check
      if ((namePriority > 3 && usersAdd.isNotEmpty && direct) || badRoomName) {
        // Filter out number of non current users to show preview of total
        final otherUsers = usersAdd.values.where(
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
              ? '${shownUser.displayName} and ${usersAdd.values.length - 1}'
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
      users: usersAdd ?? this.usersNew,
      direct: direct ?? this.direct,
      invite: invite ?? this.invite,
      limited: limited ?? this.limited,
      userIds: userIds != null ? userIds.toList() : this.userIds ?? [],
      avatarUri: avatarUri ?? this.avatarUri,
      joinRule: joinRule ?? this.joinRule,
      lastUpdate: lastUpdate > 0 ? lastUpdate : this.lastUpdate,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      namePriority: namePriority,
      reactions: reactions,
      redactions: redactions,
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
    List<Message> messages = const [],
    String lastHash,
    String prevHash, // previously fetched hash
    String nextHash,
  }) {
    try {
      bool limited;
      int lastUpdate = this.lastUpdate;
      List<Message> outbox = List<Message>.from(this.outbox ?? []);
      final messageIds = this.messageIds ?? [];

      // Converting only message events
      final hasEncrypted = messages.firstWhere(
        (msg) => msg.type == EventTypes.encrypted,
        orElse: () => null,
      );

      // See if the newest message has a greater timestamp
      if (messages.isNotEmpty && lastUpdate < messages[0].timestamp) {
        lastUpdate = messages[0].timestamp;
      }

      // limited indicates need to fetch additional data for room timelines
      if (this.limited) {
        // Check to see if the new messages contain those existing in cache
        if (messages.isNotEmpty && messageIds.isNotEmpty) {
          final messageKnown = messageIds.firstWhere(
            (id) => id == messages[0].id,
            orElse: () => null,
          );

          // Set limited to false if they now exist
          limited = messageKnown != null;
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
      final messagesMap = HashMap.fromIterable(
        messages,
        key: (message) => message.id,
        value: (message) => message,
      );

      // Remove outboxed messages
      outbox.removeWhere(
        (message) => messagesMap.containsKey(message.id),
      );

      // save messages and unique message id updates
      final messageIdsNew = Set<String>.from(messagesMap.keys);
      final messagesNew = List<Message>.from(messagesMap.values);
      final messageIdsAll = Set<String>.from(this.messageIds ?? [])
        ..addAll(messageIdsNew);

      // Save values to room
      return this.copyWith(
        outbox: outbox,
        messagesNew: messagesNew,
        messageIds: messageIdsAll.toList(),
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
      printError('[fromMessageEvents] $error');
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
    final readReceipts = Map<String, ReadReceipt>.from(this.readReceipts ?? {});

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
              final readReceiptsNew = ReadReceipt.fromReceipt(receipt);

              // update the eventId if that event already has reads
              if (!readReceipts.containsKey(key)) {
                readReceipts[key] = readReceiptsNew;
              } else {
                // otherwise, add the usersRead to the existing reads
                readReceipts[key].userReads.addAll(readReceiptsNew.userReads);
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
      readReceipts: readReceipts,
    );
  }
}
