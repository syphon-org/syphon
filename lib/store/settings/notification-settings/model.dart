import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/store/settings/notification-settings/options/types.dart';
import 'package:syphon/store/settings/notification-settings/remote/pushers/model.dart';
import 'package:syphon/store/settings/notification-settings/remote/rules/model.dart';

part 'model.g.dart';

enum ToggleType {
  Enabled,
  Disabled,
}

enum StyleType {
  Itemized,
  Latest,
  Inbox,
}

@JsonSerializable()
class NotificationSettings extends Equatable {
  final bool enabled; // notifications enabled
  final StyleType styleType;
  final ToggleType toggleType;
  final Map<String, NotificationOptions> notificationOptions; // Map<RoomId,

  // Remote Only
  final List<Rule> rules;
  final List<Pusher> pushers;

  const NotificationSettings({
    this.enabled = false,
    this.rules = const <Rule>[],
    this.pushers = const <Pusher>[],
    this.toggleType = ToggleType.Enabled,
    this.styleType = StyleType.Itemized,
    this.notificationOptions = const {},
  });

  @override
  List<Object?> get props => [
        enabled,
        toggleType,
        styleType,
        notificationOptions,
        rules,
        pushers,
      ];

  NotificationSettings copyWith({
    enabled,
    toggleType,
    styleType,
    notificationOptions,
    pushers,
    rules,
  }) =>
      NotificationSettings(
        enabled: enabled ?? this.enabled,
        toggleType: toggleType ?? this.toggleType,
        styleType: styleType ?? this.styleType,
        notificationOptions: notificationOptions ?? this.notificationOptions,
        rules: rules ?? this.rules,
        pushers: pushers ?? this.pushers,
      );

  Map<String, dynamic> toJson() => _$NotificationSettingsToJson(this);

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);
}
