import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/storage/moor/database.dart';
import 'package:moor/moor.dart' as moor;

part 'model.g.dart';

@JsonSerializable()
class User extends Equatable implements moor.Insertable<User> {
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
      debugPrint('[User.fromMatrix] $error');
      return User();
    }
  }

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  // allows converting to message companion type for saving through moor
  @override
  Map<String, moor.Expression> toColumns(bool nullToAbsent) {
    return UsersCompanion(
      userId: moor.Value(userId!),
      deviceId: moor.Value(deviceId), // current device id
      idserver: moor.Value(idserver),
      homeserver: moor.Value(homeserver),
      homeserverName: moor.Value(homeserverName),
      accessToken: moor.Value(accessToken),
      displayName: moor.Value(displayName),
      avatarUri: moor.Value(avatarUri),
    ).toColumns(nullToAbsent);
  }
}
