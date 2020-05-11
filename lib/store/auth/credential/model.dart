import 'package:equatable/equatable.dart';

class Credential extends Equatable {
  final String type;
  final String value;
  final Map<String, String> params;

  const Credential({
    this.type,
    this.value,
    this.params = const {},
  });

  Credential copyWith({
    type,
    value,
    params,
  }) {
    return Credential(
      type: type ?? this.type,
      value: value ?? this.value,
      params: params ?? this.params,
    );
  }

  @override
  List<Object> get props => [
        type,
        value,
        params,
      ];
}
