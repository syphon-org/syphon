class User {
  final int id;
  final String name;
  final String username;
  final String homeserver;
  final String accessToken;

  const User(
      {this.id, this.name, this.username, this.homeserver, this.accessToken});

  User preauthenticated({int id, String text, bool completed}) {
    return new User(
        id: id ?? this.id,
        name: text ?? this.name,
        accessToken: accessToken ?? this.accessToken);
  }

  // TODO:
  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      username.hashCode ^
      homeserver.hashCode ^
      accessToken.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          username == other.username &&
          homeserver == other.homeserver &&
          accessToken == other.accessToken;

  @override
  String toString() {
    return 'User{id: $id, name: $name, username: $username, homeserver: $homeserver, accessToken: $accessToken}';
  }
}

class UserStore {
  final User user;
  final String username;
  final String password;
  final String homeserver;
  final bool loading;

  const UserStore(
      {this.user,
      this.loading,
      this.password,
      this.username,
      this.homeserver = 'https://matrix.org'});

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
    return 'User{user: $user, username: $username, password: $password, loading: $loading}';
  }
}
