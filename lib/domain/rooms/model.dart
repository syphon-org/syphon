import 'dart:async';
import 'dart:typed_data';

// import 'package:dart_json_mapper/dart_json_mapper.dart';

import './events/model.dart';

// @jsonSerializable
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

class Room {
  final String id;
  final String name;
  final String homeserver;
  final Avatar avatar;
  final String topic;
  final bool direct;
  final bool syncing;
  final List<Event> state;
  final List<Event> events;
  final List<Event> messages;
  final int lastUpdate;
  final String startTime;
  final String endTime;

  const Room({
    this.id,
    this.name = 'New Room',
    this.homeserver,
    this.avatar,
    this.topic = '',
    this.direct = false,
    this.syncing = false,
    this.events = const [],
    this.messages = const [],
    this.state = const [],
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

  factory Room.fromSync({
    String id,
    String startTime,
    Map<String, dynamic> json,
  }) {
    final List<dynamic> rawEvents = json['timeline']['events'];
    final List<dynamic> rawStateEvents = json['state']['events'];
    final List<dynamic> rawAccountDataEvents = json['account_data']['events'];
    final List<dynamic> rawEphemeralEvents = json['ephemeral']['events'];

    final List<Event> events =
        rawEvents.map((event) => Event.fromJson(event)).toList();

    final List<Event> stateEvents =
        rawStateEvents.map((event) => Event.fromJson(event)).toList();

    // Convert basic room features
    var newRoom = Room(
      id: id,
      events: events,
      startTime: startTime,
    );

    newRoom = newRoom.fromStateEvents(stateEvents);

    return newRoom;
  }

  dynamic toJson() => {
        "id": id,
        "name": name,
        "homeserver": homeserver,
        "avatar": avatar,
      };

  @override
  String toString() {
    return '{id: $id, name: $name, state: ${state.length}, events: ${events.length}, syncing: $syncing}';
  }
}

class RoomStore {
  final bool loading;
  final bool syncing;
  final int lastUpdate;
  final Timer roomObserver;
  final List<Room> rooms;

  const RoomStore({
    this.syncing = false,
    this.loading = false,
    this.lastUpdate = 0,
    this.roomObserver,
    this.rooms = const [],
  });

  RoomStore copyWith({
    loading,
    syncing,
    lastUpdate,
    rooms,
    roomObserver,
  }) {
    return RoomStore(
      loading: loading ?? this.loading,
      syncing: syncing ?? this.syncing,
      lastUpdate: lastUpdate ?? this.lastUpdate,
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
        "lastUpdate": lastUpdate,
        "rooms": rooms,
      };

  static RoomStore fromJson(Map<String, dynamic> json) {
    if (json == null) {
      return RoomStore();
    }

    return RoomStore(
      rooms: List<Room>.from(json['rooms']),
    );
  }
}
