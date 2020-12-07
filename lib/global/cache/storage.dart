import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:redux_persist/redux_persist.dart';
import 'package:sembast/sembast.dart';
import 'package:syphon/global/cache/index.dart';
import 'package:syphon/global/cache/threadables.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/auth/state.dart';
import 'package:syphon/store/crypto/state.dart';
import 'package:syphon/store/media/state.dart';
import 'package:syphon/store/rooms/state.dart';
import 'package:syphon/store/settings/state.dart';
import 'package:syphon/store/sync/state.dart';

final List<Object> stores = [
  AuthStore(),
  SyncStore(),
  MediaStore(),
  CryptoStore(),
  SettingsStore(),
];

class CacheStorage implements StorageEngine {
  @override
  Future<Uint8List> load() async {
    final cache = CacheSecure.cacheMain;

    await Future.wait(stores.map((store) async {
      final type = store.runtimeType.toString();
      try {
        // Stopwatch stopwatchTotal = new Stopwatch()..start();
        // Stopwatch stopwatchStore = new Stopwatch()..start();
        // Fetch from database
        final table = StoreRef<String, String>.main();
        final record = table.record(store.runtimeType.toString());
        final jsonEncrypted = await record.get(cache);

        // printDebug('[CacheStorage] load ${stopwatchStore.elapsed}');

        // Decrypt from database
        final jsonDecoded = await compute(
          decryptJsonBackground,
          {
            'ivKey': CacheSecure.ivKey,
            'ivKeyNext': CacheSecure.ivKeyNext,
            'cryptKey': CacheSecure.cryptKey,
            'type': type,
            'json': jsonEncrypted,
          },
          debugLabel: 'decryptJsonBackground',
        );

        // printDebug('[CacheStorage] decrypt ${stopwatchStore.elapsed}');

        // Load for CacheSerializer to use later
        CacheSecure.cacheStores[type] = jsonDecoded;
        // printDebug('[CacheStorage] total time ${stopwatchTotal.elapsed} ');
      } catch (error) {
        printError(error.toString(), title: 'CacheStorage|$type');
      }
    }));

    // unlock redux_persist after cache loaded from sqflite
    return Uint8List(0);
  }

  @override
  Future<void> save(Uint8List data) {
    return null;
  }

  static Future<void> saveOffload(String jsonEncrypted, {String type}) async {
    final cache = CacheSecure.cacheMain;
    final table = StoreRef<String, String>.main();
    final record = table.record(type);
    await record.put(cache, jsonEncrypted);
  }
}
