import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/storage/index.dart';
import 'package:syphon/store/user/model.dart';

Future<void> saveUsers(
  Map<String, User> users, {
  Database cache,
  Database storage,
}) async {
  final store = StoreRef<String, String>('users');

  await storage.transaction((txn) async {
    for (User user in users.values) {
      final record = store.record(user.userId);
      await record.put(txn, jsonEncode(user));
    }
  });

  return Future.value();
}

Future<User> loadUser(
  String userId, {
  Database cache,
  Database storage,
}) async {
  try {
    final store = StoreRef<String, String>('users');
    final user = await store.findKey(
      storage,
      finder: Finder(
        filter: Filter.byKey(userId),
      ),
    );

    return jsonDecode(user);
  } catch (error) {
    printDebug(error);
  }
  return null;
}

Future<Map<String, User>> loadUsers({
  Database cache,
  Database storage,
  int offset = 0,
}) async {
  final Map<String, User> userMap = {};

  try {
    const limit = 2000;
    final store = StoreRef<String, String>('users');
    final count = await store.count(storage);

    final finder = Finder(
      limit: limit,
      offset: offset,
    );

    final usersPaginated = await store.find(
      storage,
      finder: finder,
    );

    if (usersPaginated.isEmpty) {
      return userMap;
    }

    for (RecordSnapshot<String, String> record in usersPaginated) {
      userMap[record.key] = User.fromJson(json.decode(record.value));
    }

    if (offset < count) {
      printDebug(
          '[userMap] cur ${userMap.length.toString()} off ${offset} total ${count}');
      userMap.addAll(await loadUsers(
        offset: offset + limit,
        storage: storage,
      ));
    }
  } catch (error) {
    printDebug(error.toString());
  }
  return userMap;
}
