import 'package:drift/drift.dart' as drift;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/database.dart';

part 'model.g.dart';

@JsonSerializable()
class User extends Equatable implements drift.Insertable<User> {
  final String? userId;
  final String? deviceId; // current device id
  final String? idserver;
  final String? homeserver;
  final String? homeserverName;
  final String? accessToken;
  final String? displayName;
  final String? avatarUri;

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
    String? userId,
    String? baseurl,
    String? deviceId,
    String? homeserver,
    String? accessToken,
    String? displayName,
    String? avatarUri,
  }) =>
      User(
        userId: userId ?? this.userId,
        deviceId: deviceId ?? this.deviceId,
        homeserver: homeserver ?? this.homeserver,
        accessToken: accessToken ?? this.accessToken,
        displayName: displayName ?? this.displayName,
        homeserverName: homeserverName ?? homeserverName,
        avatarUri: avatarUri ?? this.avatarUri,
      );

  @override
  List<Object?> get props => [
        userId,
        deviceId,
        idserver,
        homeserver,
        homeserverName,
        accessToken,
        displayName,
        avatarUri,
      ];

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
        userId: json['user_id'] as String?,
        deviceId: json['device_id'] as String?,
        idserver: (idserver ?? json['home_server']) as String?,
        homeserver: (homeserver ?? json['home_server']) as String?,
        homeserverName: json['home_server'] as String?,
        displayName: json['display_name'] as String?,
        accessToken: json['access_token'] as String?,
        avatarUri: json['avatar_url'] as String?,
      );
    } catch (error) {
      printError('[User.fromMatrix] $error');
      return User();
    }
  }

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  // allows converting to message companion type for saving through drift
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    return UsersCompanion(
      userId: drift.Value(userId!),
      deviceId: drift.Value(deviceId), // current device id
      idserver: drift.Value(idserver),
      homeserver: drift.Value(homeserver),
      homeserverName: drift.Value(homeserverName),
      accessToken: drift.Value(accessToken),
      displayName: drift.Value(displayName),
      avatarUri: drift.Value(avatarUri),
    ).toColumns(nullToAbsent);
  }
}
