import 'dart:async';

import 'package:dart_json_mapper/dart_json_mapper.dart';

import './room/model.dart';
import './events/model.dart';

class RoomStore {
  final bool loading;
  final bool syncing;
  final int lastUpdate;
  final Timer roomObserver;
  final List<Room> rooms;
  final Map<String, Room> roomMap;

  const RoomStore({
    this.syncing = false,
    this.loading = false,
    this.lastUpdate = 0,
    this.roomObserver,
    this.rooms = const [],
    this.roomMap,
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
      roomMap: roomMap ?? this.roomMap,
    );
  }

  @override
  int get hashCode =>
      loading.hashCode ^
      syncing.hashCode ^
      roomObserver.hashCode ^
      roomMap.hashCode ^
      rooms.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomStore &&
          runtimeType == other.runtimeType &&
          loading == other.loading &&
          syncing == other.syncing &&
          roomObserver == other.roomObserver &&
          roomMap == other.roomMap &&
          rooms == other.rooms;

  @override
  String toString() {
    return '{loading: $loading, syncing: $syncing, roomObserver: $roomObserver, rooms: $rooms}';
  }

  dynamic toJson() {
    try {
      final iterableEventDecorator = (value) => value.cast<Event>();
      JsonMapper.registerValueDecorator<List<Event>>(iterableEventDecorator);

      return {
        "lastUpdate": lastUpdate,
        "rooms": rooms.map((room) => JsonMapper.toJson(room)).toList(),
      };
    } catch (error) {
      print('FAILED TO JSON IN ROOM STORE $error');
      return {
        "lastUpdate": lastUpdate,
        "rooms": [],
      };
    }
  }

  static RoomStore fromJson(Map<String, dynamic> json) {
    List<Room> rooms = [];
    if (json == null) {
      return RoomStore();
    }

    if (json['rooms'] != null) {
      print('we trying ${json['rooms']}');
      rooms = JsonMapper.fromJson<List<Room>>(json['rooms']);
    }

    return RoomStore(
      lastUpdate: json['lastUpdate'],
      rooms: rooms,
    );
  }
}
