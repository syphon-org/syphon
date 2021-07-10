import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/store/events/model.dart';

part 'model.g.dart';

@JsonSerializable()
class Redaction extends Event {
  final String? redactId; // event_id

  const Redaction({
    id,
    userId,
    roomId,
    type,
    sender,
    stateKey,
    timestamp,
    content,
    data,
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

  @override
  Redaction copyWith({
    id,
    type,
    sender,
    roomId,
    stateKey,
    content,
    timestamp,
    redactId,
    data,
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
        data: data,
      );

  @override
  Map<String, dynamic> toJson() => _$RedactionToJson(this);
  factory Redaction.fromJson(Map<String, dynamic> json) => _$RedactionFromJson(json);

  factory Redaction.fromEvent(Event event) {
    return Redaction(
      id: event.id,
      userId: event.userId,
      roomId: event.roomId,
      type: event.type,
      sender: event.sender,
      stateKey: event.stateKey,
      timestamp: event.timestamp,
      redactId: event.data != null ? event.data['redacts'] : null,
    );
  }
}
