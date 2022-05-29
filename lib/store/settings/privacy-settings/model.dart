import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

@JsonSerializable()
class PrivacySettings extends Equatable {
  final Duration keyBackupInterval;

  const PrivacySettings({
    this.keyBackupInterval = const Duration(days: 1),
  });

  @override
  List<Object?> get props => [
        keyBackupInterval,
      ];

  PrivacySettings copyWith({
    Duration? keyBackupInterval,
  }) =>
      PrivacySettings(
        keyBackupInterval: keyBackupInterval ?? this.keyBackupInterval,
      );

  Map<String, dynamic> toJson() => _$PrivacySettingsToJson(this);

  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      _$PrivacySettingsFromJson(json);
}
