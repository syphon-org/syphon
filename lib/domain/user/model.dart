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

  const UserStore(
      {this.user = const User(),
      this.loading = false,
      this.password, // null
      this.username, // null
      this.isUsernameValid = false,
      this.isPasswordValid = false,
      this.homeserver = '192.168.2.20'});

  @override
  int get hashCode =>
      user.hashCode ^
      username.hashCode ^
      password.hashCode ^
      loading.hashCode ^
      homeserver.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStore &&
          runtimeType == other.runtimeType &&
          user == other.user &&
          username == other.username &&
          password == other.password &&
          homeserver == other.homeserver &&
          loading == other.loading;

  @override
  String toString() {
    return 'User{user: $user, username: $username, password: $password, homeserver: $homeserver, loading: $loading,}';
  }
}
