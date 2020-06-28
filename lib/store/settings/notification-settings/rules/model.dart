import 'package:equatable/equatable.dart';
import 'package:syphon/global/libs/hive/type-ids.dart';
import 'package:hive/hive.dart';

part 'model.g.dart';

@HiveType(typeId: RuleHiveId)
class Rule extends Equatable {
  @HiveField(0)
  final String id; // rule_id

  @HiveField(1)
  final bool enabled;

  @HiveField(2)
  final bool isDefault;

  // determine if these can be saved without being parsed
  final List<Map<String, String>> conditions;
  final List<dynamic> actions;

  const Rule({
    this.id,
    this.enabled,
    this.isDefault,
    this.conditions,
    this.actions,
  });

  @override
  List<Object> get props => [
        id,
        enabled,
        isDefault,
        conditions,
        actions,
      ];

  Rule copyWith({
    id,
    enabled,
    isDefault,
    conditions,
    actions,
  }) {
    return Rule(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      isDefault: isDefault ?? this.isDefault,
      conditions: conditions ?? this.conditions,
      actions: actions ?? this.actions,
    );
  }

  factory Rule.fromJson(dynamic json) {
    try {
      return Rule(
        id: json['rule_id'],
        enabled: json['enabled'],
        isDefault: json['default'],
        conditions: json['conditions'],
        actions: json['actions'],
      );
    } catch (error) {
      return Rule(
        id: json['rule_id'],
      );
    }
  }
}
