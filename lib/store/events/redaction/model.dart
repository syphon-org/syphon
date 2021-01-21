// Package imports:
import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/store/events/model.dart';

part 'model.g.dart';

@JsonSerializable()
class Redaction extends Event {
  final String redactId; // event_id

  const Redaction({
    id,
    userId,
    roomId,
    type,
    sender,
    stateKey,
    timestamp,
    content,
    this.redactId,
  }) : super(
          id: id,
          userId: userId,
          roomId: roomId,
          type: type,
          sender: sender,
          stateKey: stateKey,
          timestamp: timestamp,
          content: content,
        );

  Redaction copyWith({
    id,
    type,
    sender,
    roomId,
    stateKey,
    content,
    timestamp,
  }) =>
      Redaction(
        id: id ?? this.id,
        type: type ?? this.type,
        sender: sender ?? this.sender,
        roomId: roomId ?? this.roomId,
        stateKey: stateKey ?? this.stateKey,
        timestamp: timestamp ?? this.timestamp,
        content: content ?? this.content,
        redactId: redactId ?? this.redactId,
      );

  Map<String, dynamic> toJson() => _$RedactionToJson(this);
  factory Redaction.fromJson(Map<String, dynamic> json) =>
      _$RedactionFromJson(json);

  factory Redaction.fromMatrix(Map<String, dynamic> json) {
    return Redaction(
      id: json['event_id'] as String,
      userId: json['user_id'] as String,
      roomId: json['room_id'] as String,
      type: json['type'] as String,
      sender: json['sender'] as String,
      stateKey: json['state_key'] as String,
      timestamp: json['origin_server_ts'] as int,
      redactId: json['redact'] as String,
    );
  }
}
