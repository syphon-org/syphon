import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

@JsonSerializable()
class OneTimeKey extends Equatable {
  final String? userId;
  final String? deviceId;
  final Map<String, String?> keys; // Map<identityKey, key>
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
  factory OneTimeKey.fromJson(Map<String, dynamic> json) =>
      _$OneTimeKeyFromJson(json);
}
