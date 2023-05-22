import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/domain/events/model.dart';

part 'model.g.dart';

/// Redaction
///
/// Note: Redactions are ephemeral events
/// meant to mutate other events
/// These are no longer saved to any database
/// but saved by modifying other stored events
@JsonSerializable()
class Redaction extends Event {
  final String? redactId; // event_id

  const Redaction({
    super.id,
    super.userId,
    super.roomId,
    super.type,
    super.sender,
    super.stateKey,
    super.batch,
    super.prevBatch,
    super.timestamp,
    super.content,
    this.redactId,
  });

  @override
  Redaction copyWith({
    id,
    type,
    sender,
    roomId,
    stateKey,
    batch,
    prevBatch,
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
        batch: batch ?? this.batch,
        prevBatch: prevBatch ?? this.prevBatch,
        timestamp: timestamp ?? this.timestamp,
        content: content ?? this.content,
        redactId: redactId ?? this.redactId,
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
      batch: event.batch,
      prevBatch: event.prevBatch,
      timestamp: event.timestamp,
      redactId: event.data != null ? event.data['redacts'] : null,
    );
  }
}
