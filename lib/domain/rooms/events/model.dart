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
  final String userId;
  final String roomId;
  final String type;
  final String sender;
  final String stateKey;
  final int timestamp;
  final dynamic content;

  // For m.room.message only
  final String contentType;
  final String body;

  const Event({
    this.id,
    this.userId,
    this.roomId,
    this.type,
    this.sender,
    this.stateKey,
    this.content,
    this.timestamp,
    this.contentType,
    this.body,
  });

  Event copyWith({
    id,
    type,
    sender,
    roomId,
    stateKey,
    content,
    timestamp,
    contentType,
    body,
  }) {
    return Event(
        id: id ?? this.id,
        type: type ?? this.type,
        sender: sender ?? this.sender,
        roomId: roomId ?? this.roomId,
        stateKey: stateKey ?? this.stateKey,
        content: content ?? this.content,
        timestamp: timestamp ?? this.timestamp,
        contentType: contentType ?? this.contentType,
        body: body ?? this.body);
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    var body;
    var contentType;

    if (json['type'] == 'm.room.message') {
      body = json['content']['body'] as String;
      contentType = json['content']['msgtype'] as String;
    }

    return Event(
      id: json['event_id'] as String,
      userId: json['user_id'] as String,
      roomId: json['room_id'] as String,
      type: json['type'] as String,
      sender: json['sender'] as String,
      stateKey: json['state_key'] as String,
      timestamp: json['origin_server_ts'] as int,
      content: json['content'] as dynamic,
      body: body,
      contentType: contentType,
    );
  }
}
