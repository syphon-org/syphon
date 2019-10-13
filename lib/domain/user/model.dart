class User {
  final int id;
  final String name;
  final String alias;

  const User({this.id, this.name, this.alias});

  User preauthenticated({int id, String text, bool completed}) {
    return new User(
      id: id ?? this.id,
      name: text ?? this.name,
    );
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ alias.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          alias == other.alias;

  @override
  String toString() {
    return 'User{id: $id, name: $name, alias: $alias}';
  }
}

class UserStore {
  final User user;
  final String username;
  final String password;
  final bool loading;

  const UserStore({this.user, this.loading, this.password, this.username});

  @override
  int get hashCode =>
      user.hashCode ^ username.hashCode ^ password.hashCode ^ loading.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStore &&
          runtimeType == other.runtimeType &&
          user == other.user &&
          username == other.username &&
          password == other.password &&
          loading == other.loading;

  @override
  String toString() {
    return 'User{user: $user, username: $username, password: $password, loading: $loading}';
  }
}
