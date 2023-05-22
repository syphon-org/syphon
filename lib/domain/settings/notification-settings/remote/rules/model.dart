import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

@JsonSerializable()
class Rule extends Equatable {
  final String? id; // rule_id
  final bool? enabled;
  final bool? isDefault;

  // determine if these can be saved without being parsed
  final List<Map<String, String>>? conditions;
  final List<dynamic>? actions;

  const Rule({
    this.id,
    this.enabled,
    this.isDefault,
    this.conditions,
    this.actions,
  });

  @override
  List<Object?> get props => [
        id,
        enabled,
        isDefault,
        conditions,
        actions,
      ];

  Map<String, dynamic> toJson() => _$RuleToJson(this);

  factory Rule.fromJson(Map<String, dynamic> json) => _$RuleFromJson(json);

  Rule copyWith({
    id,
    enabled,
    isDefault,
    conditions,
    actions,
  }) =>
      Rule(
        id: id ?? this.id,
        enabled: enabled ?? this.enabled,
        isDefault: isDefault ?? this.isDefault,
        conditions: conditions ?? this.conditions,
        actions: actions ?? this.actions,
      );

  factory Rule.fromMatrix(dynamic json) {
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
