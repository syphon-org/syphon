import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/store/auth/state.dart';

///
/// Save Auth
///
/// saves auth state to cold storage
///
Future<void> saveAuth(
  AuthStore authStore, {
  Database storage,
}) async {
  final store = StoreRef<String, String>(StorageKeys.AUTH);

  return await storage.transaction((txn) async {
    final record = store.record(StorageKeys.AUTH);
    await record.put(txn, json.encode(authStore));
  });
}

///
/// Load Auth
///
/// loads auth state from cold storage
///
Future<AuthStore> loadAuth({Database storage}) async {
  try {
    final store = StoreRef<String, String>(StorageKeys.AUTH);

    final auth = await store.record(StorageKeys.AUTH).get(storage);

    if (auth == null) {
      return null;
    }

    return AuthStore.fromJson(json.decode(auth));
  } catch (error) {
    printError(error.toString(), tag: 'loadAuth');
    return null;
  }
}
