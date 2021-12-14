import 'dart:async';

import 'package:syphon/global/print.dart';
import 'package:syphon/storage/database.dart';
import 'package:syphon/store/user/model.dart';

///
/// Room Queries
///
extension UserQueries on StorageDatabase {
  Future<void> insertUsers(List<User> users) {
    return batch(
      (batch) => batch.insertAllOnConflictUpdate(this.users, users),
    );
  }

  Future<List<User>> selectUsers(List<String> ids, {int offset = 0, int limit = 0}) {
    return (select(users)..where((tbl) => tbl.userId.isIn(ids))).get();
  }

  Future<List<User>> selectUsersAll() {
    return (select(users)).get();
  }
}

Future<void> saveUsers(
  Map<String, User> users, {
  required StorageDatabase storage,
}) async {
  return storage.insertUsers(users.values.toList());
}

///
/// Load Users (Cold Storage)
///
Future<Map<String, User>> loadUsers({
  required StorageDatabase storage,
  List<String> ids = const [],
}) async {
  final Map<String, User> users = {};

  try {
    final users = await storage.selectUsers(ids);

    printInfo('[users] loaded ${users.length}');

    return Map.fromIterable(
      users,
      key: (user) => user.userId,
      value: (user) => user,
    );
  } catch (error) {
    printError(error.toString(), title: 'loadUsers');
    return users;
  }
}

///
/// Load Users All (Cold Storage)
///
Future<Map<String, User>> loadUsersAll({
  required StorageDatabase storage,
}) async {
  final Map<String, User> users = {};

  try {
    final users = await storage.selectUsersAll();

    printInfo('[users ALL] loaded ${users.length}');

    return Map.fromIterable(
      users,
      key: (user) => user.userId,
      value: (user) => user,
    );
  } catch (error) {
    printError(error.toString(), title: 'loadUsers');
    return users;
  }
}
