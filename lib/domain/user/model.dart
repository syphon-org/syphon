class User {
  final int id;
  final String name;

  const User({
    this.id,
    this.name,
  });

  User preauthenticated({int id, String text, bool completed}) {
    return new User(
      id: id ?? this.id,
      name: text ?? this.name,
    );
  }
}

class UserStore {
  final User user;
  final bool loading;

  const UserStore({this.user, this.loading});
}
