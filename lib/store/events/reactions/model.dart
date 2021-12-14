import 'package:drift/drift.dart' as drift;
import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/storage/database.dart';
import 'package:syphon/store/events/model.dart';

part 'model.g.dart';

@JsonSerializable()
class Reaction extends Event implements drift.Insertable<Reaction> {
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
    prevBatch,
    timestamp,
    content,
    data,
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
          prevBatch: prevBatch,
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
    prevBatch,
    content,
    timestamp,
    data, //ignore
    body,
    relType,
    relEventId,
    bool redact = false,
  }) =>
      Reaction(
        id: id ?? this.id,
        type: type ?? this.type,
        sender: sender ?? this.sender,
        roomId: roomId ?? this.roomId,
        stateKey: stateKey ?? this.stateKey,
        batch: batch ?? this.batch,
        prevBatch: prevBatch ?? this.prevBatch,
        timestamp: timestamp ?? this.timestamp,
        content: content ?? this.content,
        body: redact ? null : body ?? this.body,
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

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    return ReactionsCompanion(
      id: drift.Value(id!),
      userId: drift.Value(userId),
      roomId: drift.Value(roomId),
      type: drift.Value(type),
      sender: drift.Value(sender),
      stateKey: drift.Value(stateKey),
      batch: drift.Value(batch),
      prevBatch: drift.Value(prevBatch),
      timestamp: drift.Value(timestamp),
      body: drift.Value(body),
      relType: drift.Value(relType),
      relEventId: drift.Value(relEventId),
    ).toColumns(nullToAbsent);
  }
}
