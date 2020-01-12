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
  final bool direct;
  final bool syncing;
  final List<Event> state;
  final List<Event> events;

  const Room({
    this.id,
    this.name = 'New Room',
    this.homeserver,
    this.avatar,
    this.direct = false,
    this.syncing = false,
    this.events = const [],
    this.state = const [],
  });

  Room copyWith({
    id,
    name,
    avatar,
    direct,
    syncing,
    state,
    events,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      direct: direct ?? this.direct,
      syncing: syncing ?? this.syncing,
      state: state ?? this.state,
      events: events ?? this.events,
    );
  }

  // Find name of room based on spec naming priority
  Room fromStateEvents(List<Event> stateEvents, {String currentUsername}) {
    int priority = 4;
    Avatar avatar;

    final String name = stateEvents.fold(this.name, (name, event) {
      if (this.direct &&
          event.type == 'm.room.member' &&
          event.content['displayname'] != currentUsername) {
        return event.content['displayname'];
      }

      if (event.type == 'm.room.name') {
        priority = 1;
        return event.content['name'];
      } else if (event.type == 'm.room.canonical_alias' && priority > 2) {
        priority = 2;
        return event.content['alias'];
      } else if (event.type == 'm.room.aliases' && priority > 3) {
        priority = 3;
        return event.content['aliases'][0];
      } else if (event.type == 'm.room.avatar') {
        // Save mxc uri for thumbnail file
        final avatarFile = event.content['thumbnail_file'];
        if (avatarFile == null) {
          avatar = Avatar(uri: event.content['url']);
        }
      }

      return name;
    });

    return this.copyWith(
      name: name ?? 'New Room',
      avatar: avatar,
      state: stateEvents,
    );
  }

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
