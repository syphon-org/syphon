import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/global/libs/matrix/constants.dart';

part 'model.g.dart';

@JsonSerializable()
class Message extends Event {
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

  const Message({
    id,
    userId,
    roomId,
    type,
    sender,
    stateKey,
    timestamp,
    content,
    this.body,
    this.msgtype,
    this.format,
    this.filename,
    this.formattedBody,
    this.ciphertext,
    this.senderKey,
    this.algorithm,
    this.syncing = false,
    this.pending = false,
    this.failed = false,
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
        content: event.content,
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
