// Dart imports:
import 'dart:async';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import './room/model.dart';

part 'state.g.dart';

@JsonSerializable()
class RoomStore extends Equatable {
  final bool synced;
  final int lastUpdate; // Last timestamp for actual new info
  final Map<String, Room> rooms;

  // consider renaming to nextBatch
  // Since we last checked for new info
  final String lastSince;

  @JsonKey(ignore: true)
  final Map<String, Room> archive; // TODO: actually archive

  @JsonKey(ignore: true)
  final List<String> roomsHidden;

  @JsonKey(ignore: true)
  final bool loading;

  bool get isSynced => lastUpdate != null && lastUpdate != 0;
  List<Room> get roomList => rooms != null ? List<Room>.from(rooms.values) : [];

  const RoomStore({
    this.rooms = const {},
    this.archive = const {},
    this.synced = false,
    this.loading = false,
    this.lastUpdate = 0,
    this.lastSince,
    this.roomsHidden = const [],
  });

  @override
  List<Object> get props => [
        rooms,
        synced,
        archive,
        lastUpdate,
        lastSince,
        roomsHidden,
      ];

  RoomStore copyWith({
    rooms,
    synced,
    archive,
    loading,
    lastUpdate,
    lastSince,
    roomsHidden,
  }) =>
      RoomStore(
        rooms: rooms ?? this.rooms,
        synced: synced ?? this.synced,
        archive: archive ?? this.archive,
        loading: loading ?? this.loading,
        lastUpdate: lastUpdate ?? this.lastUpdate,
        lastSince: lastSince ?? this.lastSince,
        roomsHidden: roomsHidden ?? this.roomsHidden,
      );

  Map<String, dynamic> toJson() => _$RoomStoreToJson(this);
  factory RoomStore.fromJson(Map<String, dynamic> json) =>
      _$RoomStoreFromJson(json);
}
