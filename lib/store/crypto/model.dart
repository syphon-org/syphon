import 'package:Tether/global/libs/hive/type-ids.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'model.g.dart';

@HiveType(typeId: DeviceKeyHiveId)
class DeviceKey extends Equatable {
  @HiveField(0)
  final String userId;
  @HiveField(1)
  final String deviceId;
  @HiveField(2)
  final List<String> algorithms;
  @HiveField(3)
  final Map<String, String> keys;
  @HiveField(4)
  final Map<String, dynamic> signatures;
  @HiveField(5)
  final Map<String, String> extras;

  const DeviceKey({
    this.userId,
    this.deviceId,
    this.algorithms,
    this.keys,
    this.signatures,
    this.extras,
  });

  @override
  List<Object> get props => [
        userId,
        deviceId,
        algorithms,
        keys,
        signatures,
        extras,
      ];

  factory DeviceKey.fromJson(dynamic json) {
    try {
      return DeviceKey(
        userId: json['user_id'],
        deviceId: json['device_id'],
        algorithms: List.from(json['algorithms']),
        keys: Map.from(json['keys']),
        signatures: Map.from(json['signatures']),
        extras: Map.from(json['unsigned']),
      );
    } catch (error) {
      print('[DeviceKey.fromJson] error $error');
      return DeviceKey();
    }
  }

  @override
  String toString() {
    return '{ \n' +
        'user_id: $userId,\n' +
        'device_id: $deviceId,\n' +
        'algorithms: $algorithms,\n' +
        'keys: $keys,\n' +
        'signatures: $signatures,\n' +
        'extras: $extras,\n}';
  }
}
