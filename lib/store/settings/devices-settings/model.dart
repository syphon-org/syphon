import 'package:equatable/equatable.dart';
import 'package:Tether/global/libs/hive/type-ids.dart';
import 'package:hive/hive.dart';

part 'model.g.dart';

@HiveType(typeId: 9)
class DeviceSetting extends Equatable {
  @HiveField(0)
  final String deviceId;
  @HiveField(1)
  final String displayName;
  @HiveField(2)
  final String lastSeenIp;
  @HiveField(3)
  final int lastSeenTs;

  const DeviceSetting({
    this.deviceId,
    this.displayName,
    this.lastSeenIp,
    this.lastSeenTs,
  });

  @override
  List<Object> get props => [
        deviceId,
        displayName,
        lastSeenIp,
        lastSeenTs,
      ];

  DeviceSetting copyWith({
    String deviceId,
    String displayName,
    String lastSeenIp,
    int lastSeenTs,
  }) {
    return DeviceSetting(
      deviceId: deviceId ?? this.deviceId,
      displayName: displayName ?? this.displayName,
      lastSeenIp: lastSeenIp ?? this.lastSeenIp,
      lastSeenTs: lastSeenTs ?? this.lastSeenTs,
    );
  }

  factory DeviceSetting.fromJson(dynamic json) {
    try {
      return DeviceSetting(
        deviceId: json['device_id'],
        displayName: json['display_name'],
        lastSeenIp: json['last_seen_ip'],
        lastSeenTs: json['last_seen_ts'],
      );
    } catch (error) {
      print('[DeviceSetting.fromJson] error $error');
      return DeviceSetting();
    }
  }
}
