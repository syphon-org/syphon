class User {
  final String userId;
  final String deviceId;
  final String homeserver;
  final String accessToken;
  final String displayName;
  final String avatarUrl;

  const User(
      {this.userId,
      this.deviceId,
      this.homeserver,
      this.displayName,
      this.avatarUrl,
      this.accessToken});

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

  @override
  String toString() {
    return '{id: $deviceId,  userId: $userId, homeserver: $homeserver, accessToken: $accessToken}';
  }

  static User fromJson(dynamic json) {
    return json == null
        ? User()
        : User(
            userId: json['userId'],
            deviceId: json['deviceId'],
            homeserver: json['homeserver'],
            accessToken: json['accessToken'],
            displayName: json['displayName'],
            avatarUrl: json['avatarUrl'],
          );
  }

  Map toJson() => {
        "userId": userId,
        "deviceId": deviceId,
        "homeserver": homeserver,
        "accessToken": accessToken,
        "displayName": displayName,
        "avatarUrl": avatarUrl
      };
}

class UserStore {
  final User user;

  final bool loading;
  final String username;
  final String password;
  final String homeserver;
  final String loginType;
  final bool isUsernameValid;
  final bool isPasswordValid;
  final bool isHomeserverValid;
  final bool creating;

  const UserStore(
      {this.user = const User(),
      this.loading = false,
      this.username = '', // null
      this.password = '', // null
      this.homeserver = 'matrix.org',
      this.loginType = 'm.login.dummy',
      this.isUsernameValid = false,
      this.isPasswordValid = false,
      this.isHomeserverValid = false,
      this.creating = false});

  UserStore copyWith({
    user,
    loading,
    username,
    password,
    homeserver,
    isUsernameValid,
    isPasswordValid,
    isHomeserverValid,
    creating,
  }) {
    return UserStore(
        user: user ?? this.user,
        loading: loading ?? this.loading,
        username: username ?? this.username,
        password: password ?? this.password,
        homeserver: homeserver ?? this.homeserver,
        isUsernameValid: isUsernameValid ?? this.isUsernameValid,
        isPasswordValid: isPasswordValid ?? this.isPasswordValid,
        isHomeserverValid: isHomeserverValid ?? this.isHomeserverValid,
        creating: creating ?? this.creating);
  }

  @override
  int get hashCode =>
      user.hashCode ^
      loading.hashCode ^
      username.hashCode ^
      password.hashCode ^
      homeserver.hashCode ^
      isUsernameValid.hashCode ^
      isPasswordValid.hashCode ^
      isHomeserverValid.hashCode ^
      creating.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStore &&
          runtimeType == other.runtimeType &&
          loading == other.loading &&
          user == other.user &&
          username == other.username &&
          password == other.password &&
          homeserver == other.homeserver &&
          isUsernameValid == other.isUsernameValid &&
          isPasswordValid == other.isPasswordValid &&
          isHomeserverValid == other.isHomeserverValid &&
          creating == other.creating;

  @override
  String toString() {
    return '{user: $user, username: $username, password: $password, homeserver: $homeserver, loading: $loading}';
  }

  static UserStore fromJson(Map<String, dynamic> json) {
    return json == null
        ? UserStore()
        : UserStore(
            user: User.fromJson(json['user']),
            loading: json['loading'],
            username: json['username'],
            password: json['password'],
            homeserver: json['homeserver']);
  }

  Map toJson() => {
        "user": user.toJson(),
        "username": username,
        "password": password,
        "homeserver": homeserver,
      };
}
