import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/global/libs/matrix/auth.dart';

part 'model.g.dart';

@JsonSerializable()
class Homeserver extends Equatable {
  final String? hostname;
  final String? baseUrl;
  final String? photoUrl;
  final String? identityUrl;
  final String? loginType;
  final List<String> loginTypes;

  final String? location;
  final String? description;
  final String? founded;
  final String? responseTime;
  final String? usersActive;
  final String? roomsTotal;

  final bool valid;

  const Homeserver({
    this.hostname,
    this.baseUrl,
    this.photoUrl,
    this.identityUrl,
    this.loginType,
    this.loginTypes = const [MatrixAuthTypes.PASSWORD],
    this.location,
    this.description,
    this.usersActive,
    this.roomsTotal,
    this.founded,
    this.responseTime,
    this.valid = false,
  });

  @override
  List<Object?> get props => [
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
    String? hostname,
    String? baseUrl,
    String? photoUrl,
    String? identityUrl,
    String? loginType,
    List<String>? loginTypes,
    String? location,
    String? description,
    String? founded,
    String? responseTime,
    String? usersActive,
    String? roomsTotal,
    bool? valid,
  }) =>
      Homeserver(
        hostname: hostname ?? this.hostname,
        baseUrl: baseUrl ?? this.baseUrl,
        photoUrl: photoUrl ?? this.photoUrl,
        identityUrl: identityUrl ?? this.identityUrl,
        loginType: loginType ?? this.loginType,
        loginTypes: loginTypes ?? this.loginTypes,
        location: loginType ?? this.location,
        description: description ?? this.description,
        usersActive: usersActive ?? this.usersActive,
        roomsTotal: roomsTotal ?? this.roomsTotal,
        founded: founded ?? this.founded,
        responseTime: responseTime ?? this.responseTime,
        valid: valid ?? this.valid,
      );

  Map<String, dynamic> toJson() => _$HomeserverToJson(this);

  factory Homeserver.fromJson(Map<String, dynamic> json) => _$HomeserverFromJson(json);
}
