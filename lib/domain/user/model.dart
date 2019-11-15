class User {
  final int id;
  final String name;
  final String username;
  final String homeserver;
  final String accessToken;

  const User(
      {this.id,
      this.name,
      this.username,
      this.homeserver = '192.168.2.20',
      this.accessToken});

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
  final bool loading;

  // Extract to Matrix domain
  final String homeserver;
  final List<dynamic> homeservers;
  final List<dynamic> searchResults;

  const UserStore(
      {this.user = const User(),
      this.loading = false,
      this.password, // null
      this.username, // null
      this.homeservers = const [],
      this.searchResults = const [],
      this.homeserver = 'matrix.org'});

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
    return 'User{user: $user, username: $username, password: $password, homeserver: $homeserver, homeservers: $homeservers, loading: $loading,}';
  }
}
