// Package imports:
import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

/* 
* TODO: content will not always be a string? configure parsing data
* or more complex objects
*/
@JsonSerializable()
class Event {
  final String id; // event_id
  final String userId;
  final String roomId;
  final String type;
  final String sender;
  final String stateKey;
  final int timestamp;

  @JsonKey(ignore: true)
  final dynamic content;

  const Event({
    this.id,
    this.userId,
    this.roomId,
    this.type,
    this.sender,
    this.stateKey,
    this.content,
    this.timestamp,
  });

  Event copyWith({
    id,
    type,
    sender,
    roomId,
    stateKey,
    content,
    timestamp,
  }) =>
      Event(
        id: id ?? this.id,
        type: type ?? this.type,
        sender: sender ?? this.sender,
        roomId: roomId ?? this.roomId,
        stateKey: stateKey ?? this.stateKey,
        timestamp: timestamp ?? this.timestamp,
        content: content ?? this.content,
      );

  Map<String, dynamic> toJson() => _$EventToJson(this);
  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  factory Event.fromMatrix(Map<String, dynamic> json) => Event(
        id: json['event_id'] as String,
        userId: json['user_id'] as String,
        roomId: json['room_id'] as String,
        type: json['type'] as String,
        sender: json['sender'] as String,
        stateKey: json['state_key'] as String,
        timestamp: json['origin_server_ts'] as int,
        content: json['content'] as dynamic,
      );
}
