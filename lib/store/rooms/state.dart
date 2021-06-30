import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import './room/model.dart';

part 'state.g.dart';

@JsonSerializable()
class RoomStore extends Equatable {
  final Map<String, Room> rooms;

  @JsonKey(ignore: true)
  final bool loading;

  @JsonKey(ignore: true)
  List<Room> get roomList => List<Room>.from(rooms.values);

  const RoomStore({
    this.rooms = const {},
    this.loading = false,
  });

  @override
  List<Object> get props => [
        rooms,
      ];

  RoomStore copyWith({
    bool? loading,
    Map<String, Room>? rooms,
  }) =>
      RoomStore(
        rooms: rooms ?? this.rooms,
        loading: loading ?? this.loading,
      );

  Map<String, dynamic> toJson() => _$RoomStoreToJson(this);
  factory RoomStore.fromJson(Map<String, dynamic> json) =>
      _$RoomStoreFromJson(json);
}
