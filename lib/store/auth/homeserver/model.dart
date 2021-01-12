// Package imports:
import 'package:equatable/equatable.dart';

// part 'model.g.dart';

// @JsonSerializable()
class Homeserver extends Equatable {
  final String hostname;
  final String baseUrl;
  final String photoUrl;
  final String identityUrl;
  final String loginType;

  final String location;
  final String description;
  final String founded;
  final String responseTime;
  final String usersActive;
  final String roomsTotal;

  final bool valid;

  const Homeserver({
    this.hostname,
    this.baseUrl,
    this.photoUrl,
    this.identityUrl,
    this.loginType,
    this.location,
    this.description,
    this.usersActive,
    this.roomsTotal,
    this.founded,
    this.responseTime,
    this.valid = false,
  });

  @override
  List<Object> get props => [
        hostname,
        baseUrl,
        photoUrl,
        identityUrl,
        loginType,
        location,
        description,
        founded,
        responseTime,
        usersActive,
        roomsTotal,
        valid,
      ];

  Homeserver copyWith({
    String hostname,
    String baseUrl,
    String photoUrl,
    String identityUrl,
    String loginType,
    String location,
    String description,
    String founded,
    String responseTime,
    String usersActive,
    String roomsTotal,
    bool valid,
  }) =>
      Homeserver(
        hostname: hostname ?? this.hostname,
        baseUrl: baseUrl ?? this.baseUrl,
        photoUrl: photoUrl ?? this.photoUrl,
        identityUrl: identityUrl ?? this.identityUrl,
        loginType: loginType ?? this.loginType,
        location: loginType ?? this.location,
        description: description ?? this.description,
        usersActive: usersActive ?? this.usersActive,
        roomsTotal: roomsTotal ?? this.roomsTotal,
        founded: founded ?? this.founded,
        responseTime: responseTime ?? this.responseTime,
        valid: valid ?? this.valid ?? false,
      );

  // Map<String, dynamic> toJson() => _$CredentialToJson(this);

  // factory Credential.fromJson(Map<String, dynamic> json) =>
  //     _$CredentialFromJson(json);
}
