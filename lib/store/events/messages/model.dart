import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/events/reactions/model.dart';

part 'model.g.dart';

@JsonSerializable()
class Message extends Event {
  // message drafting
  @JsonKey(defaultValue: false)
  final bool pending;
  @JsonKey(defaultValue: false)
  final bool syncing;
  @JsonKey(defaultValue: false)
  final bool failed;

  // message editing
  @JsonKey(defaultValue: false)
  final bool edited;
  @JsonKey(defaultValue: false)
  final bool replacement;

  final String? relatedEventId;

  @JsonKey(ignore: true)
  final List<Message> edits;

  @JsonKey(ignore: true)
  final List<Reaction> reactions;

  // Message Only
  final String? body;
  final String? msgtype;
  final String? format;
  final String? filename;
  final String? formattedBody;
  final int? received;

  // Encrypted Messages only
  final String? typeAlt; // inner type of decrypted event
  final String? ciphertext;
  final String? algorithm;
  final String? sessionId;
  final String? senderKey; // Curve25519 device key which initiated the session
  final String? deviceId;

  const Message({
    String? id,
    String? userId,
    String? roomId,
    String? type,
    String? sender,
    String? stateKey,
    dynamic content,
    int timestamp = 0,
    this.body,
    this.typeAlt,
    this.msgtype,
    this.format,
    this.filename,
    this.formattedBody,
    this.received,
    this.ciphertext,
    this.senderKey,
    this.deviceId,
    this.algorithm,
    this.sessionId,
    this.relatedEventId,
    this.edited = false,
    this.syncing = false,
    this.pending = false,
    this.failed = false,
    this.replacement = false,
    this.edits = const [],
    this.reactions = const [],
  }) : super(
          id: id,
          userId: userId,
          roomId: roomId,
          type: type,
          sender: sender,
          stateKey: stateKey,
          timestamp: timestamp,
          content: content,
          data: null,
        );

  @override
  Message copyWith({
    String? id,
    String? type,
    String? sender,
    String? roomId,
    String? stateKey,
    dynamic content,
    dynamic data,
    int? timestamp,
    String? body,
    String? typeAlt, // inner type of decrypted event
    msgtype,
    format,
    filename,
    formattedBody,
    ciphertext,
    senderKey,
    deviceId,
    algorithm,
    sessionId,
    received,
    bool? syncing,
    bool? pending,
    bool? failed,
    bool? replacement,
    bool? edited,
    relatedEventId,
    edits,
    reactions,
  }) =>
      Message(
        id: id ?? this.id,
        type: type ?? this.type,
        typeAlt: typeAlt ?? this.typeAlt,
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
        received: received ?? this.received,
        ciphertext: ciphertext ?? this.ciphertext,
        senderKey: senderKey ?? this.senderKey,
        deviceId: deviceId ?? this.deviceId,
        algorithm: algorithm ?? this.algorithm,
        sessionId: sessionId ?? this.sessionId,
        syncing: syncing ?? this.syncing,
        pending: pending ?? this.pending,
        failed: failed ?? this.failed,
        replacement: replacement ?? this.replacement,
        edited: edited ?? this.edited,
        relatedEventId: relatedEventId ?? this.relatedEventId,
        edits: edits ?? this.edits,
        reactions: reactions ?? this.reactions,
      );

  @override
  Map<String, dynamic> toJson() => _$MessageToJson(this);
  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

  factory Message.fromEvent(Event event) {
    try {
      final content = event.content ?? {};
      var body = content['body'] ?? '';
      var msgtype = content['msgtype'];
      var replacement = false;
      var relatedEventId;

      final relatesTo = content['m.relates_to'];

      if (relatesTo != null && relatesTo['rel_type'] == 'm.replace') {
        replacement = true;
        relatedEventId = relatesTo['event_id'];
        body = content['m.new_content']['body'];
        msgtype = content['m.new_content']['msgtype'];
      }

      return Message(
        id: event.id,
        userId: event.userId,
        roomId: event.roomId,
        type: event.type,
        typeAlt: null,
        sender: event.sender,
        stateKey: event.stateKey,
        timestamp: event.timestamp,
        content: content,
        body: body,
        msgtype: msgtype,
        format: content['format'],
        filename: content['filename'],
        formattedBody: content['formatted_body'],
        ciphertext: content['ciphertext'] ?? '',
        algorithm: content['algorithm'],
        senderKey: content['sender_key'],
        sessionId: content['session_id'],
        deviceId: content['device_id'],
        replacement: replacement,
        relatedEventId: relatedEventId,
        received: DateTime.now().millisecondsSinceEpoch,
        failed: false,
        pending: false,
        syncing: false,
        edited: false,
      );
    } catch (error) {
      printError('[Message.fromEvent] ${error.toString()}');
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
