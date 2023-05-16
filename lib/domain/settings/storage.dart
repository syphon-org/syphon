import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:syphon/domain/settings/state.dart';
import 'package:syphon/global/libraries/secure-storage/secure-storage.dart';
import 'package:syphon/global/libraries/storage/constants.dart';
import 'package:syphon/global/libraries/storage/database.dart';
import 'package:syphon/global/print.dart';

///
/// Settings Queries - unencrypted (Cold Storage)
///
/// In storage, messages are indexed by eventId
/// In redux, they're indexed by RoomID and placed in a list
///
extension SettingsQueries on StorageDatabase {
  Future<int> insertSettingsStore(SettingsStore store) async {
    final storeJson = json.decode(json.encode(store));

    // HACK: temporary to account for sqlite versions without UPSERT
    if (Platform.isLinux) {
      return into(settings).insert(
        SettingsCompanion(
          id: Value(StorageKeys.SETTINGS),
          store: Value(storeJson),
        ),
        mode: InsertMode.insertOrReplace,
      );
    }

    return into(settings).insertOnConflictUpdate(
      SettingsCompanion(
        id: Value(StorageKeys.SETTINGS),
        store: Value(storeJson),
      ),
    );
  }

  Future<SettingsStore?> selectSettingStore() async {
    final row = await (select(settings)..where((tbl) => tbl.id.isNotNull())).getSingleOrNull();

    if (row == null) {
      return null;
    }

    return SettingsStore.fromJson(row.store ?? {});
  }
}

Future<int> saveSettings(
  SettingsStore store, {
  required StorageDatabase storage,
}) async {
  return storage.insertSettingsStore(store);
}

///
/// Load Auth Store (Cold Storage)
///
Future<SettingsStore?> loadSettings({required StorageDatabase storage}) async {
  try {
    return storage.selectSettingStore();
  } catch (error) {
    log.error(error.toString(), title: 'loadAuth');
    return null;
  }
}

const TERMS_OF_SERVICE_ACCEPTANCE_KEY = 'TERMS_OF_SERVICE_ACCEPTANCE_KEY';

final _storage = SecureStorage();

Future<dynamic> saveTermsAgreement({required int timestamp}) async {
  return _storage.write(key: TERMS_OF_SERVICE_ACCEPTANCE_KEY, value: json.encode(timestamp));
}

Future<int> loadTermsAgreement() async {
  try {
    return int.parse(await _storage.read(key: TERMS_OF_SERVICE_ACCEPTANCE_KEY) ?? '0');
  } catch (error) {
    log.error(error.toString());
    return 0;
  }
}
