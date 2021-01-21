import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/global/libs/matrix/constants.dart';

part 'model.g.dart';

@JsonSerializable()
class Reaction extends Event {
  final String body; // 'key' in matrix likely an emoji
  final String relType;
  final String relEventId;

  const Reaction({
    id,
    userId,
    roomId,
    type,
    sender,
    stateKey,
    timestamp,
    content,
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
    final content = event.content['m.relates_to'] ?? {};
    print("${event.id} ${event.content} ${event.type}");
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

  factory Reaction.fromMatrix(Map<String, dynamic> json) {
    final relations = json['content']['m.relates_to'];
    return Reaction(
      id: json['event_id'] as String,
      userId: json['user_id'] as String,
      roomId: json['room_id'] as String,
      type: json['type'] as String,
      sender: json['sender'] as String,
      stateKey: json['state_key'] as String,
      timestamp: json['origin_server_ts'] as int,
      body: relations['key'] as String,
      relType: relations['rel_type'] as String,
      relEventId: relations['event_id'] as String,
    );
  }
}
