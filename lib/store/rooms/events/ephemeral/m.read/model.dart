import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class ReadStatus {
  final String userId;
  final String roomId;
  final String eventId;
  final int timestamp;

  const ReadStatus({
    this.userId,
    this.roomId,
    this.eventId,
    this.timestamp,
  });

  ReadStatus copyWith({
    userId,
    roomId,
    eventId,
    timestamp,
  }) {
    return ReadStatus(
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      eventId: eventId ?? this.eventId,
      timestamp: userId ?? this.timestamp,
    );
  }
}
