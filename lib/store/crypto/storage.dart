import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/storage/drift/database.dart';
import 'package:syphon/store/crypto/state.dart';
import 'package:uuid/uuid.dart';

///
/// Auth Quesies - unencrypted (Cold Storage)
///
/// In storage, messages are indexed by eventId
/// In redux, they're indexed by RoomID and placed in a list
///
extension CryptoQueries on StorageDatabase {
  Future<int> insertCryptoStore(CryptoStore store) async {
    final storeJson = json.decode(json.encode(store));

    return into(cryptos).insertOnConflictUpdate(CryptosCompanion(
      id: Value(StorageKeys.CRYPTO),
      store: Value(storeJson),
    ));
  }

  Future<CryptoStore?> selectCryptoStore() async {
    final row = await (select(cryptos)..where((tbl) => tbl.id.isNotNull())).getSingleOrNull();

    if (row == null) {
      return null;
    }

    return CryptoStore.fromJson(row.store ?? {});
  }
}

Future<int> saveCrypto(
  CryptoStore store, {
  required StorageDatabase storage,
}) async {
  return storage.insertCryptoStore(store);
}

///
/// Load Auth Store (Cold Storage)
///
Future<CryptoStore?> loadCrypto({required StorageDatabase storage}) async {
  try {
    return storage.selectCryptoStore();
  } catch (error) {
    printError(error.toString(), title: 'loadAuth');
    return null;
  }
}

/// Load Crypto (Cold Storage)
///
/// In storage, the crypto store is saved in it's entirety
/// in a separate thread/isolate
Future<CryptoStore?> loadCryptoOld({required Database storage}) async {
  try {
    final store = StoreRef<String, String>(StorageKeys.CRYPTO);

    final crypto = await store.record(StorageKeys.CRYPTO).get(storage);

    if (crypto == null) {
      return null;
    }

    return CryptoStore.fromJson(json.decode(crypto));
  } catch (error) {
    printError(error.toString(), title: 'loadCrypto');
    return null;
  }
}
