import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/global/libs/matrix/encryption.dart';

part 'models.g.dart';

@JsonSerializable()
class OneTimeKey extends Equatable {
  final String? userId;
  final String? deviceId;
  // Map<identityKey, key>
  final Map<String, String?> keys;
  // Map<identityKey, <deviceId, signature>>
  final Map<String, Map<String, String>> signatures;

  const OneTimeKey({
    this.userId,
    this.deviceId,
    this.keys = const {},
    this.signatures = const {},
  });

  @override
  List<Object?> get props => [
        userId,
        deviceId,
        keys,
        signatures,
      ];

  Map<String, dynamic> toJson() => _$OneTimeKeyToJson(this);
  factory OneTimeKey.fromJson(Map<String, dynamic> json) => _$OneTimeKeyFromJson(json);
}

@JsonSerializable()
class DeviceKey extends Equatable {
  final String? userId;
  final String? deviceId;
  final List<String>? algorithms;
  final Map<String, String>? keys;
  final Map<String, dynamic>? signatures;
  final Map<String, String>? extras;

  const DeviceKey({
    this.userId,
    this.deviceId,
    this.algorithms,
    this.keys,
    this.signatures,
    this.extras,
  });

  String? get curve25519 => (keys ?? {})['${Algorithms.curve25591}:${deviceId ?? ''}'];
  String? get ed25519 => (keys ?? {})['${Algorithms.ed25519}:${deviceId ?? ''}'];

  @override
  List<Object?> get props => [
        userId,
        deviceId,
        algorithms,
        keys,
        signatures,
        extras,
      ];

  Map<String, dynamic> toMatrix() => {
        'algorithms': [
          Algorithms.olmv1,
          Algorithms.megolmv1,
        ],
        'device_id': deviceId,
        'keys': keys,
        'signatures': signatures,
        'user_id': userId,
      };

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
  factory DeviceKey.fromJson(Map<String, dynamic> json) => _$DeviceKeyFromJson(json);
}
