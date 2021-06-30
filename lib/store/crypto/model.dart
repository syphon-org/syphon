import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/global/libs/matrix/encryption.dart';

part 'model.g.dart';

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

  @override
  List<Object?> get props => [
        userId,
        deviceId,
        algorithms,
        keys,
        signatures,
        extras,
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
