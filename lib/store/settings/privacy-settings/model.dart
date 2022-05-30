import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

@JsonSerializable()
class PrivacySettings extends Equatable {
  final String lastBackupMillis;
  final Duration keyBackupInterval;

  const PrivacySettings({
    this.lastBackupMillis = '0',
    this.keyBackupInterval = Duration.zero,
  });

  @override
  List<Object?> get props => [
        lastBackupMillis,
        keyBackupInterval,
      ];

  PrivacySettings copyWith({
    String? lastBackupMillis,
    Duration? keyBackupInterval,
  }) =>
      PrivacySettings(
        lastBackupMillis: lastBackupMillis ?? this.lastBackupMillis,
        keyBackupInterval: keyBackupInterval ?? this.keyBackupInterval,
      );

  Map<String, dynamic> toJson() => _$PrivacySettingsToJson(this);

  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      _$PrivacySettingsFromJson(json);
}
