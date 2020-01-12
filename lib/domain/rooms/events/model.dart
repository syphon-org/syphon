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

class Event {
  final String id; // event_id
  final String type; //
  final String sender;
  final String roomId;
  final String stateKey;
  final int timestamp;
  final dynamic content;

  const Event({
    this.id,
    this.type,
    this.sender,
    this.roomId,
    this.stateKey,
    this.content,
    this.timestamp,
  });

  Event copyWith({
    id,
    type,
    sender,
    stateKey,
    content,
    timestamp,
  }) {
    return Event(
      id: id ?? this.id,
      type: type ?? this.type,
      sender: sender ?? this.sender,
      stateKey: stateKey ?? this.stateKey,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['event_id'] as String,
      type: json['type'] as String,
      sender: json['sender'] as String,
      stateKey: json['state_key'] as String,
      timestamp: json['origin_server_ts'] as int,
      content: json['content'] as dynamic,
    );
  }
}
