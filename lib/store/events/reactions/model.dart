import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/global/algos.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/global/libs/matrix/constants.dart';

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
          timestamp: timestamp,
          content: content,
        );

  Reaction copyWith({
    id,
    type,
    sender,
    roomId,
    stateKey,
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
        timestamp: timestamp ?? this.timestamp,
        content: content ?? this.content,
        body: body ?? this.body,
        relType: relType ?? this.relType,
        relEventId: relEventId ?? this.relEventId,
      );

  Map<String, dynamic> toJson() => _$ReactionToJson(this);
  factory Reaction.fromJson(Map<String, dynamic> json) =>
      _$ReactionFromJson(json);

  factory Reaction.fromEvent(Event event) {
    final content =
        event.content != null ? event.content['m.relates_to'] ?? {} : {};

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
