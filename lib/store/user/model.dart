import 'dart:async';

import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class User {
  final String userId;
  final String deviceId;
  final String homeserver;
  final String accessToken;
  final String displayName;
  final String avatarUrl;

  const User({
    this.userId,
    this.deviceId,
    this.homeserver,
    this.displayName,
    this.avatarUrl,
    this.accessToken,
  });

  User copyWith({
    String userId,
    String deviceId,
    String homeserver,
    String accessToken,
    String displayName,
    String avatarUrl,
  }) {
    return User(
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      homeserver: homeserver ?? this.homeserver,
      accessToken: accessToken ?? this.accessToken,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  int get hashCode =>
      userId.hashCode ^
      deviceId.hashCode ^
      homeserver.hashCode ^
      displayName.hashCode ^
      avatarUrl.hashCode ^
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
      avatarUrl: json['avatar_url'] as String,
    );
  }

  @override
  String toString() {
    return '{id: $deviceId,  userId: $userId, homeserver: $homeserver, accessToken: $accessToken}';
  }
}

@jsonSerializable
class UserStore {
  final User user;
  final String username;
  final String password;
  final String homeserver;
  final String loginType;
  final bool isUsernameValid;
  final bool isPasswordValid;
  final bool isHomeserverValid;

  // Ignore temp state properties
  @JsonProperty(ignore: true)
  final String newAvatarUri;
  @JsonProperty(ignore: true)
  final bool isUsernameAvailable;
  @JsonProperty(ignore: true)
  final bool creating;
  @JsonProperty(ignore: true)
  final bool loading;

  @JsonProperty(ignore: true)
  final StreamController<User> authObserver;

  @JsonProperty(ignore: true)
  Stream<User> get onAuthStateChanged =>
      authObserver != null ? authObserver.stream : null;

  const UserStore({
    this.user = const User(),
    this.authObserver,
    this.username = '', // null
    this.password = '', // null
    this.homeserver = 'matrix.org',
    this.loginType = 'm.login.dummy',
    this.isUsernameValid = false,
    this.isUsernameAvailable = false,
    this.isPasswordValid = false,
    this.isHomeserverValid = false,
    this.newAvatarUri,
    this.creating = false,
    this.loading = false,
  });

  UserStore copyWith({
    user,
    loading,
    username,
    password,
    homeserver,
    isUsernameValid,
    isUsernameAvailable,
    isPasswordValid,
    isHomeserverValid,
    creating,
    authObserver,
  }) {
    return UserStore(
      user: user ?? this.user,
      loading: loading ?? this.loading,
      authObserver: authObserver ?? this.authObserver,
      username: username ?? this.username,
      password: password ?? this.password,
      homeserver: homeserver ?? this.homeserver,
      isUsernameValid: isUsernameValid ?? this.isUsernameValid,
      isUsernameAvailable: isUsernameAvailable != null
          ? isUsernameAvailable
          : this.isUsernameAvailable,
      isPasswordValid: isPasswordValid ?? this.isPasswordValid,
      isHomeserverValid: isHomeserverValid ?? this.isHomeserverValid,
      newAvatarUri: newAvatarUri ?? this.newAvatarUri,
      creating: creating ?? this.creating,
    );
  }

  @override
  int get hashCode =>
      user.hashCode ^
      authObserver.hashCode ^
      username.hashCode ^
      password.hashCode ^
      homeserver.hashCode ^
      isUsernameValid.hashCode ^
      isPasswordValid.hashCode ^
      isHomeserverValid.hashCode ^
      isUsernameAvailable.hashCode ^
      loading.hashCode ^
      creating.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStore &&
          runtimeType == other.runtimeType &&
          user == other.user &&
          authObserver == other.authObserver &&
          username == other.username &&
          password == other.password &&
          homeserver == other.homeserver &&
          isUsernameValid == other.isUsernameValid &&
          isPasswordValid == other.isPasswordValid &&
          isHomeserverValid == other.isHomeserverValid &&
          isUsernameAvailable == other.isUsernameAvailable &&
          loading == other.loading &&
          creating == other.creating;

  @override
  String toString() {
    return '{user: $user, authObserver: $authObserver, username: $username, password: $password, homeserver: $homeserver, loading: $loading}';
  }
}
