import 'dart:async';

import 'package:dart_json_mapper/dart_json_mapper.dart';

import './room/model.dart';

class RoomStore {
  final bool loading;
  final bool syncing;
  final int lastUpdate;
  final Timer roomObserver;
  final Map<String, Room> rooms;

  const RoomStore({
    this.syncing = false,
    this.loading = false,
    this.lastUpdate = 0,
    this.roomObserver,
    this.rooms,
  });

  List<Room> get roomList => rooms != null ? List<Room>.from(rooms.values) : [];

  RoomStore copyWith({
    loading,
    syncing,
    lastUpdate,
    roomObserver,
    rooms,
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

  dynamic toJson() {
    if (rooms == null || rooms.isEmpty) {
      return {
        "lastUpdate": lastUpdate,
        "rooms": JsonMapper.toJson([]),
      };
    }

    return {
      "lastUpdate": lastUpdate,
      "rooms": JsonMapper.toJson(List<Room>.from(rooms.values)),
    };
  }

  static RoomStore fromJson(Map<String, dynamic> json) {
    List<Room> rooms = [];
    if (json == null) {
      return RoomStore();
    }

    if (json['rooms'] != null) {
      rooms = JsonMapper.fromJson<List<Room>>(json['rooms']);
    }

    return RoomStore(
      lastUpdate: json['lastUpdate'],
      rooms: Map.fromIterable(
        rooms,
        key: (room) => room.id,
        value: (room) => room,
      ),
    );
  }
}
