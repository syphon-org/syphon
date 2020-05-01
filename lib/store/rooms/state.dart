import 'dart:async';

import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:Tether/global/libs/hive/type-ids.dart';

import './room/model.dart';

part 'state.g.dart';

@HiveType(typeId: RoomStoreHiveId)
class RoomStore extends Equatable {
  @HiveField(0)
  final bool synced;
  @HiveField(1)
  final bool loading;
  @HiveField(2)
  final bool syncing;

  @HiveField(3)
  final int lastUpdate; // Last timestamp for actual new info

  @HiveField(4)
  final String lastSince; // Since we last checked for new info

  @HiveField(5)
  final Map<String, Room> rooms;

  final Timer roomObserver;

  bool get isSynced => lastUpdate != null && lastUpdate != 0;
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

  @override
  List<Object> get props => [
        synced,
        lastUpdate,
        lastSince,
        roomObserver,
        rooms,
      ];

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
}
