import 'dart:async';

import 'package:Tether/store/rooms/converter.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';

import './room/model.dart';

class RoomStore extends Equatable {
  final bool synced;
  final bool loading;
  final bool syncing;
  final int lastUpdate; // Last timestamp for actual new info
  final String lastSince; // Since we last checked for new info

  @JsonProperty(converter: RoomsConverter())
  final Map<String, Room> rooms;

  bool get isSynced => lastUpdate != null && lastUpdate != 0;

  @JsonProperty(ignore: true)
  final Timer roomObserver;

  @JsonProperty(ignore: true)
  List<Room> get roomList => rooms != null ? List<Room>.from(rooms.values) : [];

  const RoomStore({
    this.synced = false,
    this.syncing = false,
    this.loading = false,
    this.lastUpdate = 0,
    this.lastSince,
    this.roomObserver,
    this.rooms,
  });

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
  List<Object> get props => [
        synced,
        lastUpdate,
        lastSince,
        roomObserver,
        rooms,
      ];

  dynamic toJson() {
    if (rooms == null || rooms.isEmpty) {
      return {
        "synced": synced,
        "lastSince": lastSince,
        "lastUpdate": lastUpdate,
        "rooms": JsonMapper.toJson([]),
      };
    }

    print('roomStore toJson $rooms');

    return {
      "synced": synced,
      "lastSince": lastSince,
      "lastUpdate": lastUpdate,
      "rooms": JsonMapper.toJson(rooms),
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
