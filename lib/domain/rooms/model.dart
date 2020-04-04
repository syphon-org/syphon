import 'dart:async';

import 'package:dart_json_mapper/dart_json_mapper.dart';

import './room/model.dart';

class RoomStore {
  final bool synced;
  final bool loading;
  final bool syncing;
  final int lastUpdate; // Last timestamp for actual new info
  final String lastSince; // Since we last checked for new info
  final Timer roomObserver;
  final Map<String, Room> rooms;

  const RoomStore({
    this.synced = false,
    this.syncing = false,
    this.loading = false,
    this.lastUpdate = 0,
    this.lastSince,
    this.roomObserver,
    this.rooms,
  });

  bool get isSynced => lastUpdate != null && lastUpdate != 0;

  List<Room> get roomList => rooms != null ? List<Room>.from(rooms.values) : [];

  RoomStore copyWith({
    synced,
    loading,
    syncing,
    lastUpdate,
    roomObserver,
    lastSince,
    rooms,
  }) {
    return RoomStore(
      synced: synced ?? this.synced,
      loading: loading ?? this.loading,
      syncing: syncing ?? this.syncing,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      lastSince: lastSince ?? this.lastSince,
      roomObserver: roomObserver ?? this.roomObserver,
      rooms: rooms ?? this.rooms,
    );
  }

  @override
  int get hashCode =>
      synced.hashCode ^
      lastUpdate.hashCode ^
      lastSince.hashCode ^
      roomObserver.hashCode ^
      rooms.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomStore &&
          synced == other.synced &&
          runtimeType == other.runtimeType &&
          lastUpdate == other.lastUpdate &&
          lastSince == other.lastSince &&
          roomObserver == other.roomObserver &&
          rooms == other.rooms;

  @override
  String toString() {
    return '{loading: $loading, syncing: $syncing, roomObserver: $roomObserver, rooms: $rooms}';
  }

  dynamic toJson() {
    if (rooms == null || rooms.isEmpty) {
      return {
        "synced": synced,
        "lastSince": lastSince,
        "lastUpdate": lastUpdate,
        "rooms": JsonMapper.toJson([]),
      };
    }

    return {
      "synced": synced,
      "lastSince": lastSince,
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
      synced: json['synced'],
      lastSince: json['lastSince'],
      lastUpdate: json['lastUpdate'],
      rooms: Map.fromIterable(
        rooms,
        key: (room) => room.id,
        value: (room) => room,
      ),
    );
  }
}
