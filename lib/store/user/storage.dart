import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
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

Future<Map<String, User>> loadUsers({
  Database cache,
  Database storage,
}) async {
  final Map<String, User> userMap = {};

  try {
    final store = StoreRef<String, String>('users');
    final allUsers = await store.find(storage);

    if (allUsers.isEmpty) {
      return userMap;
    }

    for (RecordSnapshot<String, String> record in allUsers) {
      userMap[record.key] = json.decode(record.value);
    }
  } catch (error) {
    printDebug(error);
  }
  return userMap;
}
