// Package imports:
import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

/**
 * Event Models and Types
 *  
 * https://matrix.org/docs/spec/client_server/latest#m-room-message-msgtypes
 */
class AccountDataTypes {
  static const direct = 'm.direct';
  static const presence = 'm.presence';
  static const ignoredUserList = 'm.ignored_user_list';
}

class EventTypes {
  static const name = 'm.room.name';
  static const topic = 'm.room.topic';
  static const avatar = 'm.room.avatar';
  static const creation = 'm.room.create';
  static const message = 'm.room.message';
  static const encrypted = 'm.room.encrypted';
  static const member = 'm.room.member';
  static const reaction = 'm.reaction';

  static const guestAccess = 'm.room.guest_access';
  static const joinRules = 'm.room.join_rules';
  static const historyVisibility = 'm.room.history_visibility';
  static const powerLevels = 'm.room.power_levels';
  static const encryption = 'm.room.encryption';
  static const roomKey = 'm.room_key';
}

class MessageTypes {
  static const TEXT = 'm.text';
  static const EMOTE = 'm.emote';
  static const NOTICE = 'm.notice';
  static const IMAGE = 'm.text';
  static const FILE = 'm.file';
  static const AUDIO = 'm.text';
  static const LOCATION = 'm.location';
  static const VIDEO = 'm.video';
  static const ANNOTATIONO = 'm.annotation';
}

class MediumType {
  static const sms = 'sms';
  static const direct = 'direct';
  static const plaintext = 'plaintext';
  static const encryption = 'encryption';
}

@JsonSerializable()
class Event {
  final String id; // event_id
  final String userId;
  final String roomId;
  final String type;
  final String sender;
  final String stateKey;
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
  }) =>
      Event(
        id: id ?? this.id,
        type: type ?? this.type,
        sender: sender ?? this.sender,
        roomId: roomId ?? this.roomId,
        stateKey: stateKey ?? this.stateKey,
        timestamp: timestamp ?? this.timestamp,
        content: content ?? this.content,
      );

  Map<String, dynamic> toJson() => _$EventToJson(this);
  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
  factory Event.fromMatrix(Map<String, dynamic> json) => Event(
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

// TODO: make this actually inherit Event but also allow immutability (dart says no?)
@JsonSerializable()
class Message {
  final String id; // event_id
  final String userId;
  final String roomId;
  final String type;
  final String sender;
  final String stateKey;
  final int timestamp;

  final bool pending;
  final bool syncing;
  final bool failed;

  // Message Only
  final String body;
  final String msgtype;
  final String format;
  final String filename;
  final String formattedBody;

  // Encrypted Messages only
  final String ciphertext;
  final String algorithm;
  final String senderKey; // Curve25519 device key which initiated the session

  /* 
  * TODO: content will not always be a string? configure parsing data
  * or more complex objects
  */
  @JsonKey(ignore: true)
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
    this.ciphertext,
    this.senderKey,
    this.algorithm,
    this.syncing = false,
    this.pending = false,
    this.failed = false,
  });

  Map<String, dynamic> toJson() => _$MessageToJson(this);
  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

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
        ciphertext: event.content['ciphertext'] ?? '',
        algorithm: event.content['algorithm'],
        senderKey: event.content['sender_key'],
        pending: false,
        syncing: false,
        failed: false,
      );
    } catch (error) {
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
}
