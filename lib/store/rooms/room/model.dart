import 'dart:collection';
import 'package:Tether/global/libs/hive/type-ids.dart';
import 'package:Tether/store/rooms/events/ephemeral/m.read/model.dart';
import 'package:Tether/store/user/model.dart';
import 'package:Tether/store/rooms/events/model.dart';
import 'package:Tether/store/user/selectors.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'model.g.dart';

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

  @HiveField(6)
  final bool direct;
  @HiveField(7)
  final bool syncing;
  @HiveField(8)
  final bool sending;
  @HiveField(9)
  final bool isDraftRoom;

  @HiveField(11)
  final String toHash; // end of last message fetch
  @HiveField(10)
  final String fromHash; // start of last messages fetch (usually prev_batch)
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

  // TODO: not caching state events for now
  // @HiveField(19)
  final List<Event> state;
  @HiveField(20)
  final List<Message> messages;
  @HiveField(21)
  final List<Message> outbox;

  @HiveField(22)
  final bool userTyping;

  @HiveField(23)
  final int lastRead;

  @HiveField(24)
  final Map<String, ReadStatus> messageReads;

  @HiveField(25)
  final Map<String, User> users;

  const Room({
    this.id,
    this.name = 'New Chat',
    this.alias = '',
    this.homeserver,
    this.avatarUri,
    this.topic = '',
    this.direct = false,
    this.syncing = false,
    this.sending = false,
    this.draft,
    this.users,
    this.state = const [],
    this.outbox = const [],
    this.messages = const [],
    this.lastRead = 0,
    this.lastUpdate = 0,
    this.totalJoinedUsers = 0,
    this.guestEnabled = false,
    this.encryptionEnabled = false,
    this.worldReadable = false,
    this.userTyping = false,
    this.isDraftRoom = false,
    this.fromHash,
    this.toHash,
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
    direct,
    syncing,
    sending,
    lastRead,
    lastUpdate,
    totalJoinedUsers,
    guestEnabled,
    encryptionEnabled,
    userTyping,
    isDraftRoom,
    draft,
    state,
    users,
    events,
    outbox,
    messages,
    messageReads,
    fromHash,
    toHash,
    prevHash,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      alias: alias ?? this.alias,
      avatarUri: avatarUri ?? this.avatarUri,
      homeserver: homeserver ?? this.homeserver,
      direct: direct ?? this.direct,
      draft: draft ?? this.draft,
      sending: sending ?? this.sending,
      syncing: syncing ?? this.syncing,
      lastRead: lastRead ?? this.lastRead,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      totalJoinedUsers: totalJoinedUsers ?? this.totalJoinedUsers,
      guestEnabled: guestEnabled ?? this.guestEnabled,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      userTyping: userTyping ?? this.userTyping,
      isDraftRoom: isDraftRoom ?? this.isDraftRoom,
      state: state ?? this.state,
      outbox: outbox ?? this.outbox,
      messages: messages ?? this.messages,
      users: users ?? this.users,
      messageReads: messageReads ?? this.messageReads,
      toHash: toHash ?? this.toHash,
      fromHash: fromHash ?? this.fromHash,
      prevHash: prevHash ?? this.prevHash,
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
        avatarUri: json['url'], // mxc uri
        totalJoinedUsers: json['num_joined_members'],
        guestEnabled: json['guest_can_join'],
        worldReadable: json['world_readable'],
        syncing: false,
      );
    } catch (error) {
      print('[Room.fromJson] error $error');
      return Room();
    }
  }

  Room fromSync({
    User currentUser,
    Map<String, dynamic> json,
  }) {
    String toHash;
    String fromHash;
    String prevHash = this.prevHash;

    List<Event> stateEvents = [];
    List<Event> ephemeralEvents = [];
    List<Message> timelineEvents = [];
    List<Event> accountDataEvents = [];

    if (json['state'] != null) {
      final List<dynamic> rawStateEvents = json['state']['events'];

      stateEvents =
          rawStateEvents.map((event) => Event.fromJson(event)).toList();
    }

    if (json['timeline'] != null) {
      toHash = json['timeline']['to'];
      fromHash = json['timeline']['from'];
      prevHash = json['timeline']['prev_batch'];

      final List<dynamic> rawTimelineEvents = json['timeline']['events'];

      timelineEvents = rawTimelineEvents
          .map((event) => Message.fromEvent(Event.fromJson(event)))
          .toList();
    }

    if (json['ephemeral'] != null) {
      final List<dynamic> rawEphemeralEvents = json['ephemeral']['events'];

      ephemeralEvents =
          rawEphemeralEvents.map((event) => Event.fromJson(event)).toList();
    }

    if (json['account_data'] != null) {
      final List<dynamic> rawAccountEvents = json['account_data']['events'];

      accountDataEvents =
          rawAccountEvents.map((event) => Event.fromJson(event)).toList();
    }

    return this
        .fromAccountData(
          accountDataEvents,
        )
        .fromStateEvents(
          stateEvents,
          currentUser: currentUser,
        )
        .fromMessageEvents(
          timelineEvents,
          toHash: toHash,
          fromHash: fromHash,
          prevHash: prevHash,
        )
        .fromEphemeralEvents(
          ephemeralEvents,
        );
  }

  // Find details of room based on state events
  // follows spec naming priority and thumbnail downloading
  Room fromStateEvents(
    List<Event> stateEvents, {
    User currentUser,
  }) {
    String name;
    String avatarUri;
    String topic;
    bool direct;
    int namePriority = 4;
    int lastUpdate = this.lastUpdate;
    List<Event> cachedStateEvents = List<Event>();
    Map<String, User> users = this.users ?? Map<String, User>();

    try {
      stateEvents.forEach((event) {
        lastUpdate =
            event.timestamp > lastUpdate ? event.timestamp : lastUpdate;

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

            if (this.direct && this.users != null && this.users.length < 3) {
              if (displayName == null && event.sender != currentUser.userId) {
                namePriority = 0;
                name = formatShortname(event.sender);
                avatarUri = memberAvatarUri;
              } else if (displayName != null &&
                  displayName != currentUser.displayName) {
                namePriority = 0;
                name = displayName;
                avatarUri = memberAvatarUri;
              }
            }

            if (!users.containsKey(event.sender)) {
              users[event.sender] = User(
                userId: event.sender,
                displayName: displayName,
                avatarUri: memberAvatarUri,
              );
            }
            break;
          default:
            break;
        }
      });
    } catch (error) {
      print('[fromStateEvents] error $error');
    }

    return this.copyWith(
      name: name ?? this.name ?? 'New Room',
      avatarUri: avatarUri ?? this.avatarUri,
      topic: topic ?? this.topic,
      users: users ?? this.users,
      lastUpdate: lastUpdate > 0 ? lastUpdate : this.lastUpdate,
      direct: direct ?? this.direct,
      state: cachedStateEvents,
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
    String toHash,
    String fromHash,
    String prevHash,
  }) {
    try {
      int lastUpdate = this.lastUpdate;

      List<Message> messages = messageEvents ?? [];
      List<Message> outbox = List<Message>.from(this.outbox ?? []);
      List<Message> existingMessages = List<Message>.from(this.messages ?? []);

      // Converting only message events
      final newMessages =
          messages.where((event) => event.type == 'm.room.message').toList();

      // See if the newest message has a greater timestamp
      if (newMessages.isNotEmpty && lastUpdate < messages[0].timestamp) {
        lastUpdate = messages[0].timestamp;
      }

      // Combine current and existing messages on unique ids
      final messagesMap = HashMap.fromIterable(
        [existingMessages, newMessages].expand(
          (sublist) => sublist.map(
            (event) => event,
          ),
        ),
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
        messages: allMessages,
        outbox: outbox,
        lastUpdate: lastUpdate ?? this.lastUpdate,
        toHash: toHash ?? this.toHash,
        fromHash: fromHash ?? this.fromHash,
        prevHash: prevHash ?? this.prevHash,
      );
    } catch (error) {
      print('[fromMessageEvents] $error');
      return this;
    }
  }

  /**
   * Appends ephemeral events (mostly read receipts) to a
   * hashmap of eventIds linking them to users and timestamps
   */
  Room fromEphemeralEvents(
    List<Event> events,
  ) {
    var userTyping = false;
    int latestRead = this.lastRead;
    var messageReads = this.messageReads != null
        ? Map<String, ReadStatus>.from(this.messageReads)
        : Map<String, ReadStatus>();

    try {
      events.forEach((event) {
        switch (event.type) {
          case 'm.typing':
            // TODO: save which users are typing
            // if ((event.content['user_ids'] as List<dynamic>).length > 0) {
            //   userTyping = event.content['user_ids'][0];
            // }

            userTyping =
                (event.content['user_ids'] as List<dynamic>).length > 0;
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
    } catch (error) {
      print('[fromEphemeralEvents] $error');
    }

    return this.copyWith(
      userTyping: userTyping,
      messageReads: messageReads,
      lastRead: latestRead,
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
    } catch (error) {
      print('[fromEphemeralEvents] error $error');
    }

    return this.copyWith(
      direct: isDirect ?? this.direct,
    );
  }
}
