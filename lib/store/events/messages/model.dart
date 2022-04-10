import 'package:drift/drift.dart' as drift;
import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/database.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/events/reactions/model.dart';

part 'model.g.dart';

///
/// Message Model
///
/// Allows converting to Json or Database Entity using
/// JsonSerializable and Drift conversions respectively
///
@JsonSerializable()
class Message extends Event implements drift.Insertable<Message> {
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

  // Message timestamps
  @JsonKey(defaultValue: 0)
  final int received;

  // Message Only
  final String? body;
  final String? msgtype;
  final String? format;
  final String? formattedBody;
  final String? url;
  final Map<String, dynamic>? file;
  final Map<String, dynamic>? info;

  // Encrypted Messages only
  final String? typeDecrypted; // inner type of decrypted event
  final String? ciphertext;
  final String? algorithm;
  final String? sessionId;
  final String? senderKey; // Curve25519 device key which initiated the session
  final String? deviceId;
  final String? relatedEventId;
  // References
  final List<String> editIds;

  @JsonKey(ignore: true)
  final List<Reaction> reactions;

  const Message({
    String? id,
    String? userId,
    String? roomId,
    String? type,
    String? sender,
    String? stateKey,
    String? batch,
    String? prevBatch,
    dynamic content,
    int timestamp = 0,
    this.body,
    this.typeDecrypted,
    this.msgtype,
    this.format,
    this.file,
    this.url,
    this.info,
    this.formattedBody,
    this.received = 0,
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
    this.editIds = const [],
    this.reactions = const [],
  }) : super(
          id: id,
          userId: userId,
          roomId: roomId,
          type: type,
          sender: sender,
          stateKey: stateKey,
          batch: batch,
          prevBatch: prevBatch,
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
    String? prevBatch,
    String? batch,
    dynamic content,
    dynamic data,
    bool? syncing,
    bool? pending,
    bool? failed,
    bool? replacement,
    bool? edited,
    int? timestamp,
    int? received,
    String? body,
    String? typeDecrypted, // inner type of decrypted event
    String? msgtype,
    String? format,
    String? url,
    Map<String, dynamic>? file,
    Map<String, dynamic>? info,
    String? formattedBody,
    String? ciphertext,
    String? senderKey,
    String? deviceId,
    String? algorithm,
    String? sessionId,
    String? relatedEventId,
    List<String>? editIds,
    List<Reaction>? reactions,
  }) =>
      Message(
        id: id ?? this.id,
        type: type ?? this.type,
        typeDecrypted: typeDecrypted ?? this.typeDecrypted,
        sender: sender ?? this.sender,
        roomId: roomId ?? this.roomId,
        stateKey: stateKey ?? this.stateKey,
        batch: batch ?? this.batch,
        prevBatch: prevBatch ?? this.prevBatch,
        timestamp: timestamp ?? this.timestamp,
        content: content ?? this.content,
        body: body ?? this.body,
        formattedBody: formattedBody ?? this.formattedBody,
        msgtype: msgtype ?? this.msgtype,
        format: format ?? this.format,
        file: file ?? this.file,
        url: url ?? this.url,
        info: info ?? this.info,
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
        editIds: editIds ?? this.editIds,
        reactions: reactions ?? this.reactions,
      );

  // allows converting to message companion type for saving through drift
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    return MessagesCompanion(
      id: drift.Value(id!),
      userId: drift.Value(userId),
      roomId: drift.Value(roomId),
      type: drift.Value(type),
      sender: drift.Value(sender),
      stateKey: drift.Value(stateKey),
      batch: drift.Value(batch),
      prevBatch: drift.Value(prevBatch),
      syncing: drift.Value(syncing),
      pending: drift.Value(pending),
      failed: drift.Value(failed),
      replacement: drift.Value(replacement),
      edited: drift.Value(edited),
      timestamp: drift.Value(timestamp),
      received: drift.Value(received),
      body: drift.Value(body),
      msgtype: drift.Value(msgtype),
      format: drift.Value(format),
      url: drift.Value(url),
      file: drift.Value(file),
      formattedBody: drift.Value(formattedBody),
      typeDecrypted: drift.Value(typeDecrypted),
      ciphertext: drift.Value(ciphertext),
      senderKey: drift.Value(senderKey),
      deviceId: drift.Value(deviceId),
      algorithm: drift.Value(algorithm),
      sessionId: drift.Value(sessionId),
      relatedEventId: drift.Value(relatedEventId),
      editIds: drift.Value(editIds),
    ).toColumns(nullToAbsent);
  }

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
      }

      final newContent = content['m.new_content'];

      if (newContent != null) {
        body = content['m.new_content']['body'];
        msgtype = content['m.new_content']['msgtype'];
      }

      var info;
      if (content['info'] != null) {
        try {
          info = Map<String, dynamic>.from(content['info']);
        } catch (error) {
          printError('[Message.fromEvent] Info Conversion Failed $error');
        }
      }

      return Message(
        id: event.id,
        userId: event.userId,
        roomId: event.roomId,
        type: event.type,
        typeDecrypted: null,
        sender: event.sender,
        stateKey: event.stateKey,
        batch: event.batch,
        prevBatch: event.prevBatch,
        timestamp: event.timestamp,
        content: content,
        body: body,
        msgtype: msgtype,
        format: content['format'], // "org.matrix.custom.html"
        formattedBody: content['formatted_body'],
        url: content['url'],
        file: content['file'],
        info: info,
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
        batch: event.batch,
        prevBatch: event.prevBatch,
        timestamp: event.timestamp,
        pending: false,
        syncing: false,
        failed: false,
        edited: false,
      );
    }
  }
}
