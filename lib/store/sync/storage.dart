import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/storage/database.dart';
import 'package:syphon/store/sync/state.dart';

///
/// Auth Quesies - unencrypted (Cold Storage)
///
/// In storage, messages are indexed by eventId
/// In redux, they're indexed by RoomID and placed in a list
///
extension SyncQueries on StorageDatabase {
  Future<int> insertSyncStore(SyncStore store) async {
    final storeJson = json.decode(json.encode(store));

    return into(syncs).insertOnConflictUpdate(SyncsCompanion(
      id: Value(StorageKeys.SYNC),
      store: Value(storeJson),
    ));
  }

  Future<SyncStore?> selectSyncStore() async {
    final row = await (select(syncs)..where((tbl) => tbl.id.isNotNull())).getSingleOrNull();

    if (row == null) {
      return null;
    }

    return SyncStore.fromJson(row.store ?? {});
  }
}

Future<int> saveSync(
  SyncStore store, {
  required StorageDatabase storage,
}) async {
  return storage.insertSyncStore(store);
}

///
/// Load Auth Store (Cold Storage)
///
Future<SyncStore?> loadSync({required StorageDatabase storage}) async {
  try {
    return storage.selectSyncStore();
  } catch (error) {
    printError(error.toString(), title: 'loadAuth');
    return null;
  }
}
