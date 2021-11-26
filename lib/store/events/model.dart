import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

/// Event Model
///
/// batch is the previous batch token from the call
/// used to find this messagee. It's purpose is to understand
/// if messages prior to this message have been cached or need
/// to be fetched remotely.
///
@JsonSerializable()
class Event {
  final String? id; // event_id
  final String? userId;
  final String? roomId;
  final String? type;
  final String? sender;
  final String? stateKey;
  final String? batch;
  final String? prevBatch; // the end batch token after syncing / fetching these messages

  // When the event arrived on the server
  @JsonKey(defaultValue: 0)
  final int timestamp;

  @JsonKey(ignore: true)
  final dynamic content;

  @JsonKey(ignore: true)
  final dynamic data;

  const Event({
    this.id,
    this.userId,
    this.roomId,
    this.type,
    this.sender,
    this.stateKey,
    this.batch,
    this.prevBatch,
    this.content,
    this.timestamp = 0,
    this.data,
  });

  Event copyWith({
    String? id,
    String? type,
    String? sender,
    String? roomId,
    String? stateKey,
    String? batch,
    String? prevBatch,
    int? timestamp,
    dynamic content,
    dynamic data,
  }) =>
      Event(
        id: id ?? this.id,
        type: type ?? this.type,
        sender: sender ?? this.sender,
        roomId: roomId ?? this.roomId,
        stateKey: stateKey ?? this.stateKey,
        batch: batch ?? this.batch,
        prevBatch: prevBatch ?? this.prevBatch,
        timestamp: timestamp ?? this.timestamp,
        content: content ?? this.content,
        data: data ?? this.data,
      );

  Map<String, dynamic> toJson() => _$EventToJson(this);
  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  factory Event.fromMatrix(
    Map<String, dynamic> json, {
    String? roomId,
    String? batch,
    String? prevBatch,
  }) {
    // HACK: redact is the only matrix event with unique top level data values
    final data = json.containsKey('redacts') ? json : null;

    return Event(
      id: json['event_id'] as String?,
      userId: json['user_id'] as String?,
      roomId: json['room_id'] as String? ?? roomId,
      type: json['type'] as String?,
      sender: json['sender'] as String?,
      stateKey: json['state_key'] as String?,
      timestamp: json['origin_server_ts'] as int? ?? 0,
      content: json['content'] as dynamic,
      data: data,
      batch: batch,
      prevBatch: prevBatch,
    );
  }
}
