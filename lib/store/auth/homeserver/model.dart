import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

@JsonSerializable()
class Homeserver extends Equatable {
  final String? hostname;
  final String? baseUrl;
  final String? photoUrl;
  final String? identityUrl;
  final List<String> loginTypes;
  final List<String> signupTypes;

  final String? location;
  final String? description;
  final String? usersActive;
  final String? roomsTotal;
  final String? founded;

  final bool valid;

  const Homeserver({
    this.hostname,
    this.baseUrl,
    this.photoUrl,
    this.identityUrl,
    this.loginTypes = const [],
    this.signupTypes = const [],
    this.location,
    this.description,
    this.usersActive,
    this.roomsTotal,
    this.founded,
    this.valid = false,
  });

  @override
  List<Object?> get props => [
        hostname,
        baseUrl,
        photoUrl,
        identityUrl,
        location,
        description,
        founded,
        usersActive,
        roomsTotal,
        valid,
      ];

  Homeserver copyWith({
    String? hostname,
    String? baseUrl,
    String? photoUrl,
    String? identityUrl,
    String? loginType,
    List<String>? loginTypes,
    List<String>? signupTypes,
    String? location,
    String? description,
    String? founded,
    String? usersActive,
    String? roomsTotal,
    bool? valid,
  }) =>
      Homeserver(
        hostname: hostname ?? this.hostname,
        baseUrl: baseUrl ?? this.baseUrl,
        photoUrl: photoUrl ?? this.photoUrl,
        identityUrl: identityUrl ?? this.identityUrl,
        loginTypes: loginTypes ?? this.loginTypes,
        signupTypes: signupTypes ?? this.signupTypes,
        location: loginType ?? this.location,
        description: description ?? this.description,
        usersActive: usersActive ?? this.usersActive,
        roomsTotal: roomsTotal ?? this.roomsTotal,
        founded: founded ?? this.founded,
        valid: valid ?? this.valid,
      );

  Map<String, dynamic> toJson() => _$HomeserverToJson(this);

  factory Homeserver.fromJson(Map<String, dynamic> json) =>
      _$HomeserverFromJson(json);
}
