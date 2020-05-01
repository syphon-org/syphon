import 'dart:async';

import 'package:Tether/global/libs/hive/type-ids.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:hive/hive.dart';

part 'model.g.dart';

@HiveType(typeId: UserHiveId)
class User {
  @HiveField(0)
  final String userId;
  @HiveField(1)
  final String deviceId;
  @HiveField(2)
  final String homeserver;
  @HiveField(3)
  final String accessToken;
  @HiveField(4)
  final String displayName;
  @HiveField(5)
  final String avatarUri;

  const User({
    this.userId,
    this.deviceId,
    this.homeserver,
    this.displayName,
    this.avatarUri,
    this.accessToken,
  });

  User copyWith({
    String userId,
    String deviceId,
    String homeserver,
    String accessToken,
    String displayName,
    String avatarUri,
  }) {
    return User(
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      homeserver: homeserver ?? this.homeserver,
      accessToken: accessToken ?? this.accessToken,
      displayName: displayName ?? this.displayName,
      avatarUri: avatarUri ?? this.avatarUri,
    );
  }

  @override
  int get hashCode =>
      userId.hashCode ^
      deviceId.hashCode ^
      homeserver.hashCode ^
      displayName.hashCode ^
      avatarUri.hashCode ^
      accessToken.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          deviceId == other.deviceId &&
          homeserver == other.homeserver &&
          accessToken == other.accessToken;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      avatarUri: json['avatar_url'] as String,
    );
  }
}
