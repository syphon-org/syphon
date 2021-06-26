import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:syphon/global/libs/matrix/auth.dart';

part 'model.g.dart';

@JsonSerializable()
class Credential extends Equatable {
  final String? type;
  final String? value;
  final Map<String, dynamic>? params;

  const Credential({
    this.type,
    this.value,
    this.params = const {},
  });

  String? get termsUrl {
    if (params == null) {
      return null;
    }

    // TODO: use localization code to find the right one here
    return params![MatrixAuthTypes.TERMS]['policies']['privacy_policy']['en']
        ['url'];
  }

  @override
  List<Object?> get props => [
        type,
        value,
        params,
      ];

  Credential copyWith({
    type,
    value,
    params,
  }) =>
      Credential(
        type: type ?? this.type,
        value: value ?? this.value,
        params: params ?? this.params,
      );

  Map<String, dynamic> toJson() => _$CredentialToJson(this);

  factory Credential.fromJson(Map<String, dynamic> json) =>
      _$CredentialFromJson(json);
}
