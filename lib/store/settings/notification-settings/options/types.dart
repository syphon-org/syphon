// Package imports:
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'types.g.dart';

@JsonSerializable()
class NotificationOptions extends Equatable {
  final bool muted;
  final bool enabled;
  final int muteDuration;

  const NotificationOptions({
    this.muted = false,
    this.enabled = false,
    this.muteDuration = 0,
  });

  @override
  List<Object?> get props => [
        muted,
        enabled,
        muteDuration,
      ];

  NotificationOptions copyWith({
    bool? muted,
    bool? enabled,
    int? muteDuration,
  }) =>
      NotificationOptions(
        muted: muted ?? this.muted,
        enabled: enabled ?? this.enabled,
        muteDuration: muteDuration ?? this.muteDuration,
      );

  Map<String, dynamic> toJson() => _$NotificationOptionsToJson(this);

  factory NotificationOptions.fromJson(Map<String, dynamic> json) =>
      _$NotificationOptionsFromJson(json);
}
