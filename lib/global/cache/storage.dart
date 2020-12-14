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
  final Database cache;

  CacheStorage({this.cache});

  @override
  Future<Uint8List> load() async {
    await Future.wait(stores.map((store) async {
      final type = store.runtimeType.toString();
      try {
        // Fetch from database
        final table = StoreRef<String, String>.main();
        final record = table.record(store.runtimeType.toString());
        final jsonEncrypted = await record.get(cache);

        // Decrypt from database
        final jsonDecoded = await compute(
          decryptJsonBackground,
          {
            'ivKey': Cache.ivKey,
            'ivKeyNext': Cache.ivKeyNext,
            'cryptKey': Cache.cryptKey,
            'type': type,
            'json': jsonEncrypted,
          },
          debugLabel: 'decryptJsonBackground',
        );

        // Load for CacheSerializer to use later
        Cache.cacheStores[type] = jsonDecoded;
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

  Future<void> saveOffload(String jsonEncrypted, {String type}) async {
    final table = StoreRef<String, String>.main();
    final record = table.record(type);
    await record.put(cache, jsonEncrypted);
  }
}
