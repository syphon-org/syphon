// Package imports:
import 'package:equatable/equatable.dart';

// Project imports:
import 'package:syphon/global/libs/matrix/auth.dart';

class Credential extends Equatable {
  final String type;
  final String value;
  final Map<String, dynamic> params;

  const Credential({
    this.type,
    this.value,
    this.params = const {},
  });

  String get termsUrl {
    if (this.params == null) {
      return null;
    }

    // TODO: use localization code to find the right one here
    return params[MatrixAuthTypes.TERMS]['policies']['privacy_policy']['en']
        ['url'];
  }

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
