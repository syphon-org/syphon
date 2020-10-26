// Dart imports:
import 'dart:async';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

// Project imports:
import 'package:syphon/global/libs/hive/type-ids.dart';
import './room/model.dart';

part 'state.g.dart';

@HiveType(typeId: RoomStoreHiveId)
@JsonSerializable()
class RoomStore extends Equatable {
  @JsonKey(ignore: true)
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

  @JsonKey(ignore: true)
  final Map<String, Room> archive; // TODO: actually archive
  @JsonKey(ignore: true)
  final List<String> roomsHidden;

  @JsonKey(ignore: true)
  final Timer roomObserver;

  bool get isSynced => lastUpdate != null && lastUpdate != 0;
  List<Room> get roomList => rooms != null ? List<Room>.from(rooms.values) : [];

  const RoomStore({
    this.rooms = const {},
    this.archive = const {},
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
        archive,
        lastUpdate,
        lastSince,
        roomObserver,
        roomsHidden,
      ];

  RoomStore copyWith({
    rooms,
    synced,
    archive,
    loading,
    lastUpdate,
    lastSince,
    roomObserver,
    roomsHidden,
  }) =>
      RoomStore(
        rooms: rooms ?? this.rooms,
        synced: synced ?? this.synced,
        archive: archive ?? this.archive,
        loading: loading ?? this.loading,
        lastUpdate: lastUpdate ?? this.lastUpdate,
        lastSince: lastSince ?? this.lastSince,
        roomObserver: roomObserver ?? this.roomObserver,
        roomsHidden: roomsHidden ?? this.roomsHidden,
      );

  Map<String, dynamic> toJson() => _$RoomStoreToJson(this);
  factory RoomStore.fromJson(Map<String, dynamic> json) =>
      _$RoomStoreFromJson(json);
}
