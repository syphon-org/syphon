import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';


part 'model.g.dart';

@JsonSerializable()
class StorageSettings extends Equatable {
  final String keyBackupLocation;

  const StorageSettings({
    this.keyBackupLocation = '',
  });

  @override
  List<Object?> get props => [
        keyBackupLocation,
      ];

  StorageSettings copyWith({
    String? keyBackupLocation,
  }) =>
      StorageSettings(
        keyBackupLocation: keyBackupLocation ?? this.keyBackupLocation,
      );

  Map<String, dynamic> toJson() => _$StorageSettingsToJson(this);

  factory StorageSettings.fromJson(Map<String, dynamic> json) =>
      _$StorageSettingsFromJson(json);
}
