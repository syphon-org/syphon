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
}

class UserStore {
  final User user;
  final String username;
  final String password;
  final bool loading;

  const UserStore({this.user, this.loading, this.password, this.username});
}
