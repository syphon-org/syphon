// Package imports:
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

// Project imports:
import 'package:syphon/global/libs/hive/type-ids.dart';
import 'package:syphon/global/libs/matrix/encryption.dart';

part 'model.g.dart';

@HiveType(typeId: DeviceKeyHiveId)
@JsonSerializable()
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

  Map<String, dynamic> toMatrix() {
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

  factory DeviceKey.fromMatrix(dynamic json) {
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
      return DeviceKey();
    }
  }

  Map<String, dynamic> toJson() => _$DeviceKeyToJson(this);
  factory DeviceKey.fromJson(Map<String, dynamic> json) =>
      _$DeviceKeyFromJson(json);
}
