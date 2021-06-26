import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

@JsonSerializable()
class Device extends Equatable {
  final String? deviceId;
  final String? displayName;
  final String? lastSeenIp;
  final int? lastSeenTs;

  const Device({
    this.deviceId,
    this.displayName,
    this.lastSeenIp,
    this.lastSeenTs,
  });

  @override
  List<Object?> get props => [
        deviceId,
        displayName,
        lastSeenIp,
        lastSeenTs,
      ];

  Device copyWith({
    String? deviceId,
    String? displayName,
    String? lastSeenIp,
    int? lastSeenTs,
  }) =>
      Device(
        deviceId: deviceId ?? this.deviceId,
        displayName: displayName ?? this.displayName,
        lastSeenIp: lastSeenIp ?? this.lastSeenIp,
        lastSeenTs: lastSeenTs ?? this.lastSeenTs,
      );

  factory Device.fromMatrix(dynamic json) {
    try {
      return Device(
        deviceId: json['device_id'],
        displayName: json['display_name'],
        lastSeenIp: json['last_seen_ip'],
        lastSeenTs: json['last_seen_ts'],
      );
    } catch (error) {
      return Device();
    }
  }

  Map<String, dynamic> toJson() => _$DeviceToJson(this);

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
}
