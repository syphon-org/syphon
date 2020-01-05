import 'dart:async';

import './events/model.dart';

// Corresponds to rooms in the matrix protocol
class Room {
  final String id;
  final String name;
  final List<Event> state;
  final List<Event> events;
  final bool syncing;

  const Room({
    this.id,
    this.name = 'New Room',
    this.events = const [],
    this.state = const [],
    this.syncing = false,
  });

  Room copyWith({
    id,
    name,
    state,
    events,
    syncing,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      state: state ?? this.state,
      events: events ?? this.events,
      syncing: syncing ?? this.syncing,
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
