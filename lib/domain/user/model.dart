class User {
  final int id;
  final String username;
  final String homeserver;
  final String accessToken;

  const User(
      {this.id,
      this.username,
      this.homeserver = 'matrix.org',
      this.accessToken});

  User preauthenticated({int id, String text, bool completed}) {
    return new User(
        id: id ?? this.id,
        username: text ?? this.username,
        homeserver: text ?? this.homeserver,
        accessToken: accessToken ?? this.accessToken);
  }

  @override
  int get hashCode =>
      id.hashCode ^
      username.hashCode ^
      homeserver.hashCode ^
      accessToken.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          homeserver == other.homeserver &&
          accessToken == other.accessToken;

  @override
  String toString() {
    return 'User{id: $id,  username: $username, homeserver: $homeserver, accessToken: $accessToken}';
  }
}

class UserStore {
  final User user;

  final bool loading;
  final String username;
  final String password;
  final String homeserver;
  final bool isUsernameValid;
  final bool isPasswordValid;
  final bool isHomeserverValid;
  final bool creating;

  const UserStore(
      {this.user = const User(),
      this.loading = false,
      this.username = "", // null
      this.password, // null
      this.homeserver = '192.168.2.20',
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
    return 'User{user: $user, username: $username, password: $password, homeserver: $homeserver, loading: $loading,}';
  }
}
