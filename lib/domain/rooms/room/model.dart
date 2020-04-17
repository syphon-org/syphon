import 'dart:collection';
import 'dart:typed_data';
import 'package:Tether/domain/rooms/events/selectors.dart';
import 'package:Tether/domain/user/model.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:Tether/domain/rooms/events/model.dart';
import 'package:flutter/foundation.dart';

@jsonSerializable
class Avatar {
  final String uri;
  final String url;
  final String type;
  final Uint8List data;

  const Avatar({
    this.uri,
    this.url,
    this.type,
    this.data,
  });
  Avatar copyWith({
    uri,
    url,
    type,
    data,
  }) {
    return Avatar(
      uri: uri ?? this.uri,
      url: url ?? this.url,
      type: type ?? this.type,
      data: data ?? this.data,
    );
  }

  @override
  String toString() {
    return '{\n' +
        'uri: $uri,\n' +
        'url: $url,\b' +
        'type: $type,\n' +
        'data: $data,\n' +
        '}';
  }
}

@jsonSerializable
class Room {
  final String id;
  final String name;
  final String homeserver;
  final Avatar avatar;
  final String topic;
  final bool direct;
  final bool syncing;
  final bool sending;
  final String startTime;
  final String endTime;
  final int lastUpdate;

  // Event lists
  final List<User> users;
  final List<Event> state;
  final List<Message> messages;
  final List<Message> outbox;
  final Message draft;

  const Room({
    this.id,
    this.name = 'New Room',
    this.homeserver,
    this.avatar,
    this.topic = '',
    this.direct = false,
    this.syncing = false,
    this.sending = false,
    this.draft,
    this.users = const [],
    this.state = const [],
    this.outbox = const [],
    this.messages = const [],
    this.lastUpdate = 0,
    this.startTime,
    this.endTime,
  });

  Room copyWith({
    id,
    name,
    homeserver,
    avatar,
    topic,
    direct,
    syncing,
    sending,
    startTime,
    endTime,
    lastUpdate,
    draft,
    state,
    users,
    events,
    outbox,
    messages,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      homeserver: homeserver ?? this.homeserver,
      avatar: avatar ?? this.avatar,
      direct: direct ?? this.direct,
      sending: sending ?? this.sending,
      syncing: syncing ?? this.syncing,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      state: state ?? this.state,
      outbox: outbox ?? this.outbox,
      messages: messages ?? this.messages,
      users: users ?? this.users,
    );
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    try {
      return Room(
        id: json['room_id'],
        name: json['name'],
        homeserver: (json['room_id'] as String).split(':')[1],
        topic: json['topic'],
        avatar: Avatar(uri: json['url']), // mxc://
        // TODO: add from public room json response
        // TODO: canonical_alias
        // TODO: num_joined_members | members
        // TODO: world_readable
        // TODO: guest_can_joi
        syncing: false,
      );
    } catch (error) {
      print('[Room.fromPublicRoom] error $error');
      return Room();
    }
  }

  Room fromMessageEvents(
    List<Event> messageEvents, {
    String startTime,
    String endTime,
  }) {
    int lastUpdate = this.lastUpdate;
    List<Event> existingMessages =
        this.messages.isNotEmpty ? List<Event>.from(this.messages) : [];
    List<Message> outbox =
        this.outbox.isNotEmpty ? List<Message>.from(this.outbox) : [];
    List<Event> messages = messageEvents ?? [];

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
          (event) => event is Message ? event : Message.fromEvent(event),
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
  }

  // Find details of room based on state events
  // follows spec naming priority and thumbnail downloading
  Room fromStateEvents(
    List<Event> stateEvents, {
    String originDEBUG,
    String username,
    int limit,
  }) {
    String name;
    Avatar avatar;
    String topic;
    int namePriority = 4;
    int lastUpdate = this.lastUpdate;
    List<Event> cachedStateEvents = List<Event>();
    List<User> users = List<User>();

    try {
      stateEvents.forEach((event) {
        lastUpdate =
            event.timestamp > lastUpdate ? event.timestamp : lastUpdate;

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
              // Keep previous avatar url until the new uri is fetched
              avatar = this.avatar != null ? this.avatar : Avatar();
              avatar = avatar.copyWith(
                uri: event.content['url'],
              );
            }
            break;
          case 'm.room.member':
            if (this.direct && event.content['displayname'] != username) {
              name = event.content['displayname'];
            }
            if (event.content['membership'] == 'membership') {
              print('m.room.memeber ${event.content}');
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
      avatar: avatar ?? this.avatar,
      topic: topic ?? this.topic,
      lastUpdate: lastUpdate > 0 ? lastUpdate : this.lastUpdate,
      state: cachedStateEvents,
    );
  }

  Room fromSync({
    String username,
    Map<String, dynamic> json,
  }) {
    // contains message events
    final List<dynamic> rawTimelineEvents = json['timeline']['events'];
    final List<dynamic> rawStateEvents = json['state']['events'];

    // print(json['summary']);
    // print(json['ephemeral']);
    // Check for message events
    // print('TIMELINE OUTPUT ${json['timeline']}');
    // TODO: final List<dynamic> rawAccountDataEvents = json['account_data']['events'];
    // TODO: final List<dynamic> rawEphemeralEvents = json['ephemeral']['events'];

    final List<Event> stateEvents =
        rawStateEvents.map((event) => Event.fromJson(event)).toList();

    final List<Event> messageEvents =
        rawTimelineEvents.map((event) => Event.fromJson(event)).toList();

    return this
        .fromStateEvents(
          stateEvents,
          username: username,
          originDEBUG: '[fetchSync]',
        )
        .fromMessageEvents(
          messageEvents,
        );
  }

  @override
  String toString() {
    return '{\n' +
        'id: $id,\n' +
        'name: $name,\n' +
        'homeserver: $homeserver,\n' +
        'direct: $direct,\n' +
        'syncing: $syncing,\n' +
        'state: $state,\n' +
        'avatar: $avatar,\n' +
        '}';
  }
}
