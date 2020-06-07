import 'package:Tether/global/libs/hive/type-ids.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'model.g.dart';

@HiveType(typeId: UserHiveId)
class User extends Equatable {
  @HiveField(0)
  final String userId;
  @HiveField(1)
  final String deviceId; // current device id
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
  List<Object> get props => [
        userId,
        deviceId,
        homeserver,
        displayName,
        avatarUri,
        accessToken,
      ];

  factory User.fromJson(dynamic json) {
    try {
      return User(
        userId: json['user_id'] as String,
        deviceId: json['device_id'] as String,
        homeserver: json['home_server'] as String,
        displayName: json['display_name'] as String,
        accessToken: json['access_token'] as String,
        avatarUri: json['avatar_url'] as String,
      );
    } catch (error) {
      print('[User.fromJson] $error');
      return User();
    }
  }
}
