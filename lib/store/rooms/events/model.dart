// Package imports:
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

// Project imports:
import 'package:syphon/global/libs/hive/type-ids.dart';

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

  // {membership: join, displayname: usbfingers, avatar_url: mxc://matrix.org/RrRcMHnqXaJshyXZpGrZloyh }
  // {is_direct: true, membership: invite, displayname: ereio, avatar_url: mxc://matrix.org/JllILpqzdFAUOvrTPSkDryzW}
  static const member = 'm.room.member';

  static const guestAccess = 'm.room.guest_access';
  static const joinRules = 'm.room.join_rules';
  static const historyVisibility = 'm.room.history_visibility';
  static const powerLevels = 'm.room.power_levels';
  static const encryption = 'm.room.encryption';
  static const roomKey = 'm.room_key';

  static const ignoredUserList = 'm.ignored_user_list';
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
}

class MediumType {
  static const sms = 'sms';
  static const direct = 'direct';
  static const plaintext = 'plaintext';
  static const encryption = 'encryption';
}

@HiveType(typeId: EventHiveId)
@JsonSerializable()
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
@HiveType(typeId: MessageHiveId)
@JsonSerializable()
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

  // Encrypted Messages only
  @HiveField(15)
  final String ciphertext;
  @HiveField(16)
  final String algorithm;
  // The Curve25519 key of the device which initiated the session originally.
  @HiveField(17)
  final String senderKey;

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
