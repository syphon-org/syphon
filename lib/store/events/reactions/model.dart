import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/store/events/model.dart';

part 'model.g.dart';

@JsonSerializable()
class Reaction extends Event {
  final String? body; // 'key' in matrix likely an emoji
  final String? relType;
  final String? relEventId;

  const Reaction({
    id,
    userId,
    roomId,
    type,
    sender,
    stateKey,
    batch,
    timestamp,
    content,
    data, //ignore
    this.body,
    this.relType,
    this.relEventId,
  }) : super(
          id: id,
          userId: userId,
          roomId: roomId,
          type: type,
          sender: sender,
          stateKey: stateKey,
          batch: batch,
          timestamp: timestamp,
          content: content,
        );

  @override
  Reaction copyWith({
    id,
    type,
    sender,
    roomId,
    stateKey,
    batch,
    content,
    timestamp,
    data, //ignore
    body,
    relType,
    relEventId,
  }) =>
      Reaction(
        id: id ?? this.id,
        type: type ?? this.type,
        sender: sender ?? this.sender,
        roomId: roomId ?? this.roomId,
        stateKey: stateKey ?? this.stateKey,
        batch: batch ?? this.batch,
        timestamp: timestamp ?? this.timestamp,
        content: content ?? this.content,
        body: body ?? this.body,
        relType: relType ?? this.relType,
        relEventId: relEventId ?? this.relEventId,
      );

  @override
  Map<String, dynamic> toJson() => _$ReactionToJson(this);
  factory Reaction.fromJson(Map<String, dynamic> json) => _$ReactionFromJson(json);

  factory Reaction.fromEvent(Event event) {
    final content = event.content != null ? event.content['m.relates_to'] ?? {} : {};

    return Reaction(
      id: event.id,
      userId: event.userId,
      roomId: event.roomId,
      type: event.type,
      sender: event.sender,
      stateKey: event.stateKey,
      timestamp: event.timestamp,
      body: content['key'],
      relType: content['rel_type'],
      relEventId: content['event_id'],
    );
  }
}
