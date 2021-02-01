import 'dart:convert';

import 'package:redux/redux.dart';
import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/store/crypto/state.dart';

/**
 * Save Crypto Store
 * 
 * Save the crypto store to cold storage
 * Idealy, run this after performance a pure action
 */
Future<void> saveCrypto(
  CryptoStore cryptoStore, {
  Database storage,
}) async {
  final store = StoreRef<String, String>(StorageKeys.CRYPTO);

  return await storage.transaction((txn) async {
    final record = store.record(StorageKeys.CRYPTO);
    await record.put(txn, json.encode(cryptoStore));
  });
}

/**
 * Load Crypto (Cold Storage)
 * 
 * In storage, the crypto store is saved in it's entirety 
 * in a separate thread/isolate 
 */
Future<CryptoStore> loadCrypto({Database storage}) async {
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
