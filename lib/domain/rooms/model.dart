import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import './events/model.dart';

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
}

// Corresponds to rooms in the matrix protocol
class Room {
  final String id;
  final String name;
  final String homeserver;
  final Avatar avatar;
  final String topic;
  final int lastUpdate;
  final bool direct;
  final bool syncing;
  final List<Event> state;
  final List<Event> events;
  final List<Event> messages;
  final String startTime;
  final String endTime;

  const Room({
    this.id,
    this.name = 'New Room',
    this.homeserver,
    this.avatar,
    this.topic = '',
    this.lastUpdate = 0,
    this.direct = false,
    this.syncing = false,
    this.events = const [],
    this.messages = const [],
    this.state = const [],
    this.startTime,
    this.endTime,
  });

  Room copyWith({
    id,
    name,
    homeserver,
    avatar,
    topic,
    lastUpdate,
    direct,
    syncing,
    state,
    events,
    messages,
    startTime,
    endTime,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      homeserver: homeserver ?? this.homeserver,
      avatar: avatar ?? this.avatar,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      direct: direct ?? this.direct,
      syncing: syncing ?? this.syncing,
      state: state ?? this.state,
      events: events ?? this.events,
      messages: messages ?? this.messages,
    );
  }

  Room fromMessageEvents(
    Map<String, dynamic> messagesJson,
  ) {
    messagesJson.keys.map((key) => print('$key\n'));
    final String startTime = messagesJson['start'];
    final String endTime = messagesJson['end'];
    final List<dynamic> messagesChunk = messagesJson['chunk'];

    // Retain where mutates
    messagesChunk
        .retainWhere((eventJson) => eventJson['type'] == 'm.room.message');

    // Converting only message events
    final List<Event> messageEvents = messagesChunk.map((eventJson) {
      return Event.fromJson(eventJson);
    }).toList();

    return this.copyWith(
      messages: messageEvents,
      startTime: startTime,
      endTime: endTime,
    );
  }

  // Find details of room based on state events
  // follows spec naming priority and thumbnail downloading
  Room fromStateEvents(List<Event> stateEvents, {String currentUsername}) {
    String name;
    Avatar avatar;
    String topic;
    int lastUpdate = 0;
    int namePriority = 4;

    stateEvents.forEach((event) {
      lastUpdate = event.timestamp > lastUpdate ? event.timestamp : lastUpdate;

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
            avatar = Avatar(uri: event.content['url']);
          }
          break;
        case 'm.room.member':
          if (this.direct && event.content['displayname'] != currentUsername) {
            name = event.content['displayname'];
          }
          break;
        default:
          break;
      }
    });

    return this.copyWith(
      name: name ?? 'New Room',
      avatar: avatar,
      topic: topic,
      state: stateEvents,
      lastUpdate: lastUpdate,
    );
  }

  // TODO: use fromStateEvents above
  factory Room.fromJsonSync(Map<String, dynamic> json) {
    if (json == null) {
      return Room();
    }
    // Dart needs this or it won't be able to dynamicly cast
    final List<dynamic> rawEvents = json['timeline']['events'];

    // Convert all of the events and save
    final List<Event> events =
        rawEvents.map((event) => Event.fromJson(event)).toList();

    // HACK: to find room name
    final Event nameEvent = events
        .firstWhere((event) => event.type == "m.room.name", orElse: () => null);

    return Room(
      id: json['id'] as String,
      name: nameEvent != null ? nameEvent.content['name'] : 'Loading...',
      events: events,
    );
  }

  @override
  String toString() {
    return '{id: $id, name: $name, state: ${state.length}, events: ${events.length}, syncing: $syncing}';
  }
}

class RoomStore {
  final bool loading;
  final bool syncing;
  final Timer roomObserver;
  final List<Room> rooms;

  const RoomStore({
    this.syncing = false,
    this.loading = false,
    this.roomObserver,
    this.rooms = const [],
  });

  RoomStore copyWith({
    loading,
    syncing,
    rooms,
    roomObserver,
  }) {
    return RoomStore(
      loading: loading ?? this.loading,
      syncing: syncing ?? this.syncing,
      roomObserver: roomObserver ?? this.roomObserver,
      rooms: rooms ?? this.rooms,
    );
  }

  @override
  int get hashCode =>
      loading.hashCode ^
      syncing.hashCode ^
      roomObserver.hashCode ^
      rooms.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomStore &&
          runtimeType == other.runtimeType &&
          loading == other.loading &&
          syncing == other.syncing &&
          roomObserver == other.roomObserver &&
          rooms == other.rooms;

  @override
  String toString() {
    return '{loading: $loading, syncing: $syncing, roomObserver: $roomObserver, rooms: $rooms}';
  }

  Map<String, dynamic> toJson() => {
        "rooms": rooms.toString(),
      };

  static RoomStore fromJson(Map<String, dynamic> json) {
    return json == null
        ? RoomStore()
        : RoomStore(
            rooms: json['rooms']['join']
                .map((rawRoom) => Room.fromJsonSync(rawRoom))
                .toList(),
          );
  }
}
