import 'dart:async';

import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:syphon/global/libs/hive/type-ids.dart';

import './room/model.dart';

part 'state.g.dart';

@HiveType(typeId: RoomStoreHiveId)
class RoomStore extends Equatable {
  final bool loading;

  @HiveField(0)
  final bool synced;

  @HiveField(3)
  final int lastUpdate; // Last timestamp for actual new info

  // consider renaming to nextBatch
  @HiveField(4)
  final String lastSince; // Since we last checked for new info

  @HiveField(5)
  final Map<String, Room> rooms;

  // TODO: actually archive
  final List<String> roomsHidden;

  final Timer roomObserver;

  bool get isSynced => lastUpdate != null && lastUpdate != 0;
  List<Room> get roomList => rooms != null ? List<Room>.from(rooms.values) : [];

  const RoomStore({
    this.rooms = const {},
    this.synced = false,
    this.loading = false,
    this.lastUpdate = 0,
    this.lastSince,
    this.roomObserver,
    this.roomsHidden = const [],
  });

  @override
  List<Object> get props => [
        rooms,
        synced,
        lastUpdate,
        lastSince,
        roomObserver,
        roomsHidden,
      ];

  RoomStore copyWith({
    rooms,
    synced,
    loading,
    lastUpdate,
    lastSince,
    roomObserver,
    roomsHidden,
  }) {
    return RoomStore(
      rooms: rooms ?? this.rooms,
      synced: synced ?? this.synced,
      loading: loading ?? this.loading,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      lastSince: lastSince ?? this.lastSince,
      roomObserver: roomObserver ?? this.roomObserver,
      roomsHidden: roomsHidden ?? this.roomsHidden,
    );
  }
}
