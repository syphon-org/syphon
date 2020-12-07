// Dart imports:
import 'dart:async';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import './room/model.dart';

part 'state.g.dart';

@JsonSerializable()
class RoomStore extends Equatable {
  final Map<String, Room> rooms;

  @JsonKey(ignore: true)
  final List<String> archive; // TODO: archive by ID

  @JsonKey(ignore: true)
  final List<String> roomsHidden; // TODO: hidden by ID

  @JsonKey(ignore: true)
  final bool loading;

  @JsonKey(ignore: true)
  List<Room> get roomList => rooms != null ? List<Room>.from(rooms.values) : [];

  const RoomStore({
    this.rooms = const {},
    this.archive = const [],
    this.loading = false,
    this.roomsHidden = const [],
  });

  @override
  List<Object> get props => [
        rooms,
        archive,
        roomsHidden,
      ];

  RoomStore copyWith({
    rooms,
    archive,
    loading,
    lastSince,
    roomsHidden,
  }) =>
      RoomStore(
        rooms: rooms ?? this.rooms,
        archive: archive ?? this.archive,
        loading: loading ?? this.loading,
        roomsHidden: roomsHidden ?? this.roomsHidden,
      );

  Map<String, dynamic> toJson() => _$RoomStoreToJson(this);
  factory RoomStore.fromJson(Map<String, dynamic> json) =>
      _$RoomStoreFromJson(json);
}
