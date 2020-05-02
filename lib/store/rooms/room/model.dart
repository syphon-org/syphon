import 'dart:collection';
import 'package:Tether/global/libs/hive/type-ids.dart';
import 'package:Tether/store/rooms/events/ephemeral/m.read/model.dart';
import 'package:Tether/store/user/model.dart';
import 'package:Tether/store/rooms/events/model.dart';
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

  @HiveField(10)
  final String startTime;
  @HiveField(11)
  final String endTime;

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

  // TODO: consider making this a map
  @HiveField(18)
  final List<User> users;

  @HiveField(19)
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
    this.users = const [],
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
    this.startTime,
    this.endTime,
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
    startTime,
    endTime,
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
      print('[Room.fromPublicRoom] error $error');
      return Room();
    }
  }

  Room fromMessageEvents(
    List<Message> messageEvents, {
    String startTime,
    String endTime,
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
      if (newMessages.isNotEmpty && messages[0].timestamp > lastUpdate) {
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

      outbox.removeWhere((message) => messagesMap.containsKey(message.id));

      // Confirm sorting the messages here, I think this should be done by the
      final combinedMessages = List<Message>.from(messagesMap.values);

      // Add to room
      return this.copyWith(
        messages: combinedMessages,
        outbox: outbox,
        lastUpdate: lastUpdate ?? this.lastUpdate,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
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
    List<Event> events, {
    String originDEBUG,
  }) {
    var userTyping = false;
    int latestRead = this.lastRead;
    var messageReads = this.messageReads != null
        ? Map<String, ReadStatus>.from(this.messageReads)
        : Map<String, ReadStatus>();

    try {
      if (events.length > 0) {
        print('[${this.name}] saving ephemeral ${events.length}');
      }
      events.forEach((event) {
        switch (event.type) {
          case 'm.typing':
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
            print('[fromEphemeralEvents] unknown event type ${event.type}');
            break;
        }
      });
    } catch (error) {
      print('[fromEphemeralEvents] error $error');
    }

    return this.copyWith(
      userTyping: userTyping,
      messageReads: messageReads,
      lastRead: latestRead,
    );
  }

  // Find details of room based on state events
  // follows spec naming priority and thumbnail downloading
  Room fromStateEvents(
    List<Event> stateEvents, {
    String originDEBUG,
    String currentUser,
    int limit,
  }) {
    String name;
    String avatarUri;
    String topic;
    bool isDirect;
    int namePriority = 4;
    int lastUpdate = this.lastUpdate;
    List<Event> cachedStateEvents = List<Event>();
    List<User> users = List<User>();
    // TODO: List<User> users = List<User>();

    try {
      stateEvents.forEach((event) {
        lastUpdate =
            event.timestamp > lastUpdate ? event.timestamp : lastUpdate;

        print('${event.type} ${event.content}\n');

        switch (event.type) {
          case 'm.room.name':
            namePriority = 1;
            name = event.content['name'];
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
            if (event.content['displayname'] != currentUser) {
              if (this.direct || (event.content['is_direct'] as bool)) {
                isDirect = event.content['is_direct'];
                name = event.content['displayname'];
                avatarUri = event.content['avatar_url'];
              }
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
      lastUpdate: lastUpdate > 0 ? lastUpdate : this.lastUpdate,
      direct: isDirect ?? this.direct,
      state: cachedStateEvents,
    );
  }

  Room fromSync({
    String currentUser,
    Map<String, dynamic> json,
  }) {
    // print(json['summary']);
    // print('TIMELINE OUTPUT ${json['timeline']}');
    // TODO: final List<dynamic> rawAccountDataEvents = json['account_data']['events'];

    // Check for message events
    final List<dynamic> rawStateEvents = json['state']['events'];
    final List<dynamic> rawTimelineEvents =
        json['timeline']['events']; // contains message events
    final List<dynamic> rawEphemeralEvents = json['ephemeral']['events'];

    final List<Event> ephemeralEvents =
        rawEphemeralEvents.map((event) => Event.fromJson(event)).toList();

    final List<Event> stateEvents =
        rawStateEvents.map((event) => Event.fromJson(event)).toList();

    final List<Message> messageEvents = rawTimelineEvents
        .map((event) => Message.fromEvent(Event.fromJson(event)))
        .toList();

    return this
        .fromStateEvents(
          stateEvents,
          currentUser: currentUser,
          originDEBUG: '[fetchSync]',
        )
        .fromMessageEvents(
          messageEvents,
        )
        .fromEphemeralEvents(
          ephemeralEvents,
        );
  }

  @override
  String toString() {
    return '{\n' +
        '\tid: $id,\n' +
        '\tname: $name,\n' +
        '\thomeserver: $homeserver,\n' +
        '\tdirect: $direct,\n' +
        '\tsyncing: $syncing,\n' +
        '\tstate: $state,\n' +
        '\tusers: $users\n'
            '}';
  }
}
