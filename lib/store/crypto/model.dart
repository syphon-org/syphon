import 'package:Tether/global/libs/hive/type-ids.dart';
import 'package:Tether/global/libs/matrix/encryption.dart';
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

  // DEPRRECATED
  @HiveField(6)
  final Map<String, String> privateKeys;

  const DeviceKey({
    this.userId,
    this.deviceId,
    this.algorithms,
    this.keys,
    this.signatures,
    this.extras,
    this.privateKeys,
  });

  @override
  List<Object> get props => [
        userId,
        deviceId,
        algorithms,
        keys,
        signatures,
        extras,
        privateKeys,
      ];

  factory DeviceKey.fromJson(dynamic json) {
    try {
      return DeviceKey(
        userId: json['user_id'],
        deviceId: json['device_id'],
        algorithms: List.from(json['algorithms']),
        keys: Map.from(json['keys']),
        signatures: Map.from(json['signatures']),
        extras: json['unsigned'] != null ? Map.from(json['unsigned']) : null,
      );
    } catch (error) {
      print('[DeviceKey.fromJson] error $error');
      return DeviceKey();
    }
  }

  toMap() {
    return {
      'algorithms': [
        Algorithms.olmv1,
        Algorithms.megolmv1,
      ],
      'device_id': deviceId,
      'keys': keys,
      'signatures': signatures,
      'user_id': userId,
    };
  }

  @override
  String toString() {
    return '{' +
        'user_id: $userId,' +
        'device_id: $deviceId,' +
        'algorithms: $algorithms,' +
        'keys: $keys,' +
        'signatures: $signatures,' +
        'extras: $extras,' +
        '}\n';
  }
}
