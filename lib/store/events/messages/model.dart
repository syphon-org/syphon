import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/global/libs/matrix/constants.dart';

part 'model.g.dart';

@JsonSerializable()
class Message extends Event {
  final bool pending;
  final bool syncing;
  final bool failed;

  // message editing
  final bool edited;
  final bool replacement;
  final String replacementId; // TODO: relatedEventIds

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
    this.replacement = false,
    this.edited = false,
    this.replacementId,
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

  @override
  Message copyWith({
    id,
    type,
    sender,
    roomId,
    stateKey,
    content,
    timestamp,
    body,
    msgtype,
    format,
    filename,
    formattedBody,
    ciphertext,
    senderKey,
    algorithm,
    syncing = false,
    pending = false,
    failed = false,
    replacement = false,
    edited = false,
    replacementId,
  }) =>
      Message(
        id: id ?? this.id,
        type: type ?? this.type,
        sender: sender ?? this.sender,
        roomId: roomId ?? this.roomId,
        stateKey: stateKey ?? this.stateKey,
        timestamp: timestamp ?? this.timestamp,
        content: content ?? this.content,
        body: body ?? this.body,
        formattedBody: formattedBody ?? this.formattedBody,
        msgtype: msgtype ?? this.msgtype,
        format: format ?? this.format,
        filename: filename ?? this.filename,
        ciphertext: ciphertext ?? this.ciphertext,
        senderKey: senderKey ?? this.senderKey,
        algorithm: algorithm ?? this.algorithm,
        syncing: syncing ?? this.syncing ?? false,
        pending: pending ?? this.pending ?? false,
        failed: failed ?? this.failed ?? false,
        replacement: replacement ?? this.replacement ?? false,
        edited: edited ?? this.edited ?? false,
        replacementId: replacementId ?? this.replacementId,
      );

  Map<String, dynamic> toJson() => _$MessageToJson(this);
  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  factory Message.fromEvent(Event event) {
    try {
      var body = event.content['body'] ?? '';
      var msgtype = event.content['msgtype'];
      var replacement = false;
      var replacementId;

      if ((event.content as Map).containsKey('m.relates_to')) {
        replacement = event.content['m.relates_to']['rel_type'] == 'm.replace';
        replacementId = event.content['m.relates_to']['event_id'];
        body = event.content['m.new_content']['body'];
        msgtype = event.content['m.new_content']['msgtype'];
      }

      return Message(
        id: event.id,
        userId: event.userId,
        roomId: event.roomId,
        type: event.type,
        sender: event.sender,
        stateKey: event.stateKey,
        timestamp: event.timestamp,
        content: event.content,
        body: body,
        msgtype: msgtype,
        format: event.content['format'],
        filename: event.content['filename'],
        formattedBody: event.content['formatted_body'],
        ciphertext: event.content['ciphertext'] ?? '',
        algorithm: event.content['algorithm'],
        senderKey: event.content['sender_key'],
        replacement: replacement,
        replacementId: replacementId,
        failed: false,
        pending: false,
        syncing: false,
        edited: false,
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
        edited: false,
      );
    }
  }
}
