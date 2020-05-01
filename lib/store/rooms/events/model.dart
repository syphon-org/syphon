import 'package:hive/hive.dart';
import 'package:Tether/global/libs/hive/type-ids.dart';

part 'model.g.dart';

/**
 * Event Models and Types
 * 
 * I'd really love to use inheritance here
 */
class EventTypes {
  static const MESSAGE = 'm.room.message';
  static const ROOM_CREATION = 'm.room.create';
  static const ROOM_NAME = '.room.name';
  static const ROOM_TOPIC = 'm.room.topic';
  static const ROOM_MEMBER = 'm.room.member';
  static const GUEST_ACCESS = 'm.room.guest_access';
  static const JOIN_RULES = 'm.room.join_rules';
  static const HISTORY_VISIBILITY = 'm.room.history_visibility';
  static const POWER_LEVELS = 'm.room.power_levels';
}

/** https://matrix.org/docs/spec/client_server/latest#m-room-message-msgtypes
   * 
    13.2.1.7.1   m.text
    13.2.1.7.2   m.emote
    13.2.1.7.3   m.notice
    13.2.1.7.4   m.image
    13.2.1.7.5   m.file
    13.2.1.7.6   m.audio
    13.2.1.7.7   m.location
    13.2.1.7.8   m.video 
   *
   */

class MessageTypes {
  static const TEXT = 'm.text';
  static const EMOTE = 'm.emote';
  static const NOTICE = 'm.notice';
  static const IMAGE = 'm.text';
  static const FILE = 'm.file';
  static const AUDIO = 'm.text';
  static const LOCATION = 'm.location';
  static const VIDEO = 'm.video';
}

@HiveType(typeId: EventHiveId)
class Event {
  @HiveField(0)
  final String id; // event_id
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final String roomId;
  @HiveField(3)
  final String type;
  @HiveField(4)
  final String sender;
  @HiveField(5)
  final String stateKey;
  @HiveField(6)
  final int timestamp;

  /* 
  * TODO: content will not always be a string? configure parsing data
  * or more complex objects
  */
  final dynamic content;

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

// TODO: make this actually inherit Event but also allow immutability (dart says no?)
@HiveType(typeId: MessageHiveId)
class Message {
  @HiveField(0)
  final String id; // event_id
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final String roomId;
  @HiveField(3)
  final String type;
  @HiveField(4)
  final String sender;
  @HiveField(5)
  final String stateKey;
  @HiveField(6)
  final int timestamp;

  @HiveField(7)
  final bool pending;
  @HiveField(8)
  final bool syncing;
  @HiveField(9)
  final bool failed;

  // Message Only
  @HiveField(10)
  final String body;
  @HiveField(11)
  final String msgtype;
  @HiveField(12)
  final String format;
  @HiveField(13)
  final String filename;
  @HiveField(14)
  final String formattedBody;

  /* 
  * TODO: content will not always be a string? configure parsing data
  * or more complex objects
  */
  final dynamic content;

  const Message({
    this.id,
    this.userId,
    this.roomId,
    this.type,
    this.sender,
    this.stateKey,
    this.timestamp,
    this.body,
    this.msgtype,
    this.format,
    this.filename,
    this.formattedBody,
    this.content,
    this.syncing = false,
    this.pending = false,
    this.failed = false,
  });

  factory Message.fromEvent(Event event) {
    try {
      return Message(
        id: event.id,
        userId: event.userId,
        roomId: event.roomId,
        type: event.type,
        sender: event.sender,
        stateKey: event.stateKey,
        timestamp: event.timestamp,
        // extracted content
        body: event.content['body'] ?? '',
        msgtype: event.content['msgtype'],
        format: event.content['format'],
        filename: event.content['filename'],
        formattedBody: event.content['formatted_body'],
        pending: false,
        syncing: false,
        failed: false,
      );
    } catch (error) {
      print('[Message.fromEvent] error ${event.id} ${event.type},');
      return Message(
        id: event.id,
        userId: event.userId,
        roomId: event.roomId,
        body: '',
        type: event.type,
        sender: event.sender,
        stateKey: event.stateKey,
        timestamp: event.timestamp,
        pending: false,
        syncing: false,
        failed: false,
      );
    }
  }
  @override
  String toString() {
    return '${this.runtimeType}{ \n' +
        'id: $id,\n' +
        'userId: $userId,\n' +
        'roomId: $roomId,\n' +
        'type: $type,\n' +
        'content: $content,\n' +
        'body: $body,\n';
  }
}
