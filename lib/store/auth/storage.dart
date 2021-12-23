import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/storage/database.dart';
import 'package:syphon/store/auth/state.dart';

///
/// Auth Quesies - unencrypted (Cold Storage)
///
/// In storage, messages are indexed by eventId
/// In redux, they're indexed by RoomID and placed in a list
///
extension AuthQueries on StorageDatabase {
  Future<int> insertAuthStore(AuthStore store) async {
    final storeJson = json.decode(json.encode(store));

    return into(auths).insertOnConflictUpdate(AuthsCompanion(
      id: Value(StorageKeys.AUTH),
      store: Value(storeJson),
    ));
  }

  Future<AuthStore?> selectAuthStore() async {
    final row = await (select(auths)..where((tbl) => tbl.id.isNotNull())).getSingleOrNull();

    if (row == null) {
      return null;
    }

    return AuthStore.fromJson(row.store ?? {});
  }
}

Future<int> saveAuth(
  AuthStore authStore, {
  required StorageDatabase storage,
}) async {
  return storage.insertAuthStore(authStore);
}

///
/// Load Auth Store (Cold Storage)
///
Future<AuthStore?> loadAuth({required StorageDatabase storage}) async {
  try {
    return storage.selectAuthStore();
  } catch (error) {
    printError(error.toString(), title: 'loadAuth');
    return null;
  }
}
