import 'dart:async';
import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/store/user/model.dart';

Future<void> saveUsers(
  Map<String, User> users, {
  Database? cache,
  required Database storage,
}) async {
  final store = StoreRef<String?, String>(StorageKeys.USERS);

  return await storage.transaction((txn) async {
    for (User user in users.values) {
      final record = store.record(user.userId);
      await record.put(txn, jsonEncode(user));
    }
  });
}

/**
 * Load Users (Cold Storage)
 * 
 * Example of useful recursion
 */
Future<Map<String, User>> loadUsers({
  Database? cache,
  required Database storage,
  int offset = 0,
  int page = 5000,
}) async {
  final Map<String, User> users = {};

  try {
    final store = StoreRef<String, String>(StorageKeys.USERS);
    final count = await store.count(storage);

    final finder = Finder(
      limit: page,
      offset: offset,
    );

    final usersPaginated = await store.find(
      storage,
      finder: finder,
    );

    if (usersPaginated.isEmpty) {
      return users;
    }

    for (RecordSnapshot<String, String> record in usersPaginated) {
      users[record.key] = User.fromJson(json.decode(record.value));
    }

    if (offset < count) {
      users.addAll(await loadUsers(
        offset: offset + page,
        storage: storage,
      ));
    }

    if (users.isEmpty) {
      return {};
    }

    printInfo('[users] loaded ${users.length}');
    return users;
  } catch (error) {
    printError(error.toString(), title: 'loadUsers');
    return {};
  }
}
