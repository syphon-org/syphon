// Package imports:
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

// Project imports:
import './pushers/model.dart';
import './rules/model.dart';

part 'model.g.dart';

@JsonSerializable()
class NotificationSettings extends Equatable {
  final List<Rule>? rules;
  final List<Pusher>? pushers;

  const NotificationSettings({this.pushers, this.rules});

  @override
  List<Object?> get props => [
        pushers,
        rules,
      ];

  NotificationSettings copyWith({
    pushers,
    rules,
  }) =>
      NotificationSettings(
        pushers: pushers ?? this.pushers,
        rules: rules ?? this.rules,
      );

  Map<String, dynamic> toJson() => _$NotificationSettingsToJson(this);

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);
}
