import 'package:dart_json_mapper/dart_json_mapper.dart';

enum EventType {
  // Actual Messages
  MESSAGE, // m.room.message

  // Significant Details
  ROOM_CREATION, // m.room.create
  ROOM_NAME, // m.room.name
  ROOM_TOPIC, // m.room.topic
  ROOM_MEMBER, // m.room.member

  // Config
  GUEST_ACCESS, // m.room.guest_access
  JOIN_RULES, // m.room.join_rules
  HISTORY_VISIBILITY, // m.room.history_visibility
  POWER_LEVELS, // m.room.power_levels
}

@jsonSerializable
class Event {
  final String id; // event_id
  final String userId;
  final String roomId;
  final String type;
  final String sender;
  final String stateKey;
  final int timestamp;

  @JsonProperty(ignore: true)
  final dynamic content;

  // For m.room.message only
  String get body => content != null ? content['body'] : null;
  String get contentType => content != null ? content['msgtype'] : null;

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
  }) {
    return Event(
      id: id ?? this.id,
      type: type ?? this.type,
      sender: sender ?? this.sender,
      roomId: roomId ?? this.roomId,
      stateKey: stateKey ?? this.stateKey,
      timestamp: timestamp ?? this.timestamp,
      content: content ?? this.content,
    );
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
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
}
