// Package imports:
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

// Project imports:
import 'package:syphon/global/libs/hive/type-ids.dart';
import './pushers/model.dart';
import './rules/model.dart';

part 'model.g.dart';

@HiveType(typeId: NotificationSettingsHiveId)
class NotificationSettings extends Equatable {
  @HiveField(0)
  final List<Pusher> pushers;

  @HiveField(1)
  final List<Rule> rules;

  const NotificationSettings({
    this.pushers,
    this.rules,
  });

  @override
  List<Object> get props => [
        pushers,
        rules,
      ];

  NotificationSettings copyWith({
    pushers,
    rules,
  }) {
    return NotificationSettings(
      pushers: pushers ?? this.pushers,
      rules: rules ?? this.rules,
    );
  }
}
