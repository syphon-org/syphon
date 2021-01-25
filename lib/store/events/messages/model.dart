import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/events/reactions/model.dart';

part 'model.g.dart';

@JsonSerializable()
class Message extends Event {
  final bool pending;
  final bool syncing;
  final bool failed;

  // message editing
  @JsonKey(defaultValue: false)
  final bool edited;

  @JsonKey(defaultValue: false)
  final bool replacement;

  final String relatedEventId;

  @JsonKey(ignore: true)
  final List<Message> edits;

  @JsonKey(ignore: true)
  final List<Reaction> reactions;

  // Message Only
  final String body;
  final String msgtype;
  final String format;
  final String filename;
  final String formattedBody;
  final int received;

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
    data,
    this.body,
    this.msgtype,
    this.format,
    this.filename,
    this.formattedBody,
    this.ciphertext,
    this.senderKey,
    this.algorithm,
    this.received,
    this.syncing = false,
    this.pending = false,
    this.failed = false,
    this.replacement = false,
    this.relatedEventId,
    this.edits = const [],
    this.reactions = const [],
    this.edited = false,
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
    received,
    syncing = false,
    pending = false,
    failed = false,
    replacement = false,
    edited = false,
    relatedEventId,
    edits,
    reactions,
    data,
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
        received: received ?? this.received,
        replacement: replacement ?? this.replacement ?? false,
        edited: edited ?? this.edited ?? false,
        relatedEventId: relatedEventId ?? this.relatedEventId,
        edits: edits ?? this.edits,
        reactions: reactions ?? this.reactions,
      );

  Map<String, dynamic> toJson() => _$MessageToJson(this);
  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  factory Message.fromEvent(Event event) {
    try {
      var body = event.content['body'] ?? '';
      var msgtype = event.content['msgtype'];
      var replacement = false;
      var relatedEventId;

      final relatesTo = event.content['m.relates_to'];

      if (relatesTo != null && relatesTo['rel_type'] == 'm.replace') {
        replacement = true;
        relatedEventId = relatesTo['event_id'];
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
        relatedEventId: relatedEventId,
        received: DateTime.now().millisecond,
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
