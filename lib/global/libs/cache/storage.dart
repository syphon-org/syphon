import 'package:flutter/foundation.dart';
import 'package:redux_persist/redux_persist.dart';
import 'package:sembast/sembast.dart';
import 'package:syphon/domain/auth/state.dart';
import 'package:syphon/domain/crypto/state.dart';
import 'package:syphon/domain/rooms/state.dart';
import 'package:syphon/domain/sync/state.dart';
import 'package:syphon/global/libs/cache/index.dart';
import 'package:syphon/global/libs/cache/threadables.dart';
import 'package:syphon/global/print.dart';

class CacheStorage implements StorageEngine {
  final Database? cache;

  CacheStorage({this.cache});

  @override
  Future<Uint8List> load() async {
    final List<Object> stores = [
      AuthStore(),
      SyncStore(),
      CryptoStore(),
      RoomStore(),
    ];

    await Future.wait(stores.map((store) async {
      final type = store.runtimeType.toString();
      try {
        // Fetch from database
        final table = StoreRef<String, String>.main();
        final record = table.record(store.runtimeType.toString());
        final jsonEncrypted = await record.get(cache!);

        // Decrypt from database
        final jsonDecoded = await compute(
          decryptJsonBackground,
          {
            'type': type,
            'json': jsonEncrypted,
            'cacheKey': Cache.cacheKey,
          },
          debugLabel: 'decryptJsonBackground',
        );

        // Load for CacheSerializer to use later
        Cache.cacheStores[type] = jsonDecoded;
      } catch (error) {
        log.error(error.toString(), title: 'CacheStorage|$type');
      }
    }));

    // unlock redux_persist after cache loaded from sqflite
    return Uint8List(0);
  }

  @override
  Future<void> save(Uint8List? data) {
    return Future.value();
  }
}
