// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

// Project imports:
import 'package:syphon/global/libs/hive/type-ids.dart';

part 'model.g.dart';

@HiveType(typeId: UserHiveId)
@JsonSerializable()
class User extends Equatable {
  @HiveField(0)
  final String userId;
  @HiveField(1)
  final String deviceId; // current device id
  @HiveField(7)
  final String idserver;
  @HiveField(2)
  final String homeserver;
  @HiveField(6)
  final String homeserverName;
  @HiveField(3)
  final String accessToken;
  @HiveField(4)
  final String displayName;
  @HiveField(5)
  final String avatarUri;

  const User({
    this.userId,
    this.deviceId,
    this.idserver,
    this.homeserver,
    this.homeserverName,
    this.accessToken,
    this.displayName,
    this.avatarUri,
  });

  User copyWith({
    String userId,
    String baseurl,
    String deviceId,
    String homeserver,
    String accessToken,
    String displayName,
    String avatarUri,
  }) =>
      User(
        userId: userId ?? this.userId,
        deviceId: deviceId ?? this.deviceId,
        homeserver: homeserver ?? this.homeserver,
        accessToken: accessToken ?? this.accessToken,
        displayName: displayName ?? this.displayName,
        homeserverName: homeserverName ?? this.homeserverName,
        avatarUri: avatarUri ?? this.avatarUri,
      );

  @override
  List<Object> get props => [
        userId,
        deviceId,
        idserver,
        homeserver,
        homeserverName,
        accessToken,
        displayName,
        avatarUri,
      ];

  Map<String, dynamic> toJson() => _$UserToJson(this);

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  factory User.fromMatrix(dynamic json) {
    try {
      var idserver;
      var homeserver;

      if (json['well_known'] != null) {
        if (json['well_known']['m.identity_server'] != null) {
          idserver = json['well_known']['m.identity_server']['base_url'];
          idserver = idserver.replaceAll('https://', '');
        }
        if (json['well_known']['m.homeserver'] != null) {
          homeserver = json['well_known']['m.homeserver']['base_url'];
          homeserver = homeserver.replaceAll('https:', '');
          homeserver = homeserver.replaceAll('/', '');
        }
      }

      return User(
        userId: json['user_id'] as String,
        deviceId: json['device_id'] as String,
        idserver: (idserver ?? json['home_server']) as String,
        homeserver: (homeserver ?? json['home_server']) as String,
        homeserverName: json['home_server'] as String,
        displayName: json['display_name'] as String,
        accessToken: json['access_token'] as String,
        avatarUri: json['avatar_url'] as String,
      );
    } catch (error) {
      debugPrint('[User.fromMatrix] $error');
      return User();
    }
  }
}
