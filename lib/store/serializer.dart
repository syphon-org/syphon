// Dart imports:
import 'dart:convert';
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:redux_persist/redux_persist.dart';
import 'package:steel_crypt/steel_crypt.dart';
import 'package:syphon/global/algos.dart';

// Project imports:
import 'package:syphon/global/libs/hive/index.dart';
import 'package:syphon/store/crypto/state.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/sync/state.dart';
import 'package:syphon/store/user/state.dart';
import './auth/state.dart';
import './media/state.dart';
import './rooms/state.dart';
import './settings/state.dart';

/**
 * Cache Serializer
 * 
 * Handles serialization, encryption, and storage for caching redux stores
 */
class CacheSerializer implements StateSerializer<AppState> {
  @override
  Uint8List encode(AppState state) {
    final stores = [
      state.authStore,
      state.syncStore,
      state.cryptoStore,
      state.roomStore,
      state.mediaStore,
      state.settingsStore,
      state.userStore,
    ];

    // Queue up a cache saving will wait
    // if the previously schedule task has not finished
    Future.microtask(() async {
      // TODO: re-enable IV rotation
      // // create a new IV for the encrypted cache
      // Cache.ivKey = createIVKey();
      // // backup the IV in case the app is force closed before caching finishes
      // await saveIVKeyNext(Cache.ivKey);

      // run through all redux stores for encryption and encoding
      await Future.wait(stores.map((store) async {
        try {
          Stopwatch stopwatchNew = new Stopwatch()..start();

          var jsonData;

          // encode the store contents to json
          // HACK: unable to pass both listed stores direct to an isolate
          final sensitiveStorage = [AuthStore, SyncStore, CryptoStore];
          if (!sensitiveStorage.contains(store.runtimeType)) {
            jsonData = await compute(jsonEncode, store);
          } else {
            jsonData = json.encode(store);
          }

          // encrypt the store contents previously converted to json
          final encryptedStore = await compute(encryptJsonBackground, {
            'ivKey': Cache.ivKey,
            'cryptKey': Cache.cryptKey,
            'type': store.runtimeType.toString(),
            'json': jsonData,
          });

          // cache the encrypted json representation of the redux store
          if (store.runtimeType == RoomStore) {
            await Cache.cacheRooms.put(
              store.runtimeType.toString(),
              encryptedStore,
            );
          }

          // cache the encrypted json representation of the redux store
          if (store.runtimeType == CryptoStore) {
            await Cache.cacheCrypto.put(
              store.runtimeType.toString(),
              encryptedStore,
            );
          }

          // cache the encrypted json representation of the redux store
          await Cache.cacheMain.put(
            store.runtimeType.toString(),
            encryptedStore,
          );

          final endTime = stopwatchNew.elapsed;
          print(
            '[Hive Serializer ENCODE] ${store.runtimeType.toString().toUpperCase()} $endTime',
          );
        } catch (error) {
          debugPrint(
              '[Hive Serializer ENCODE] ${store.runtimeType.toString().toUpperCase()} $error');
        }
      }));

      // TODO: re-enable IV rotation
      // // Rotate encryption for the next save
      // await saveIVKey(Cache.ivKey);
    });

    // Disregard redux persist storage saving
    return null;
  }

  AppState decode(Uint8List data) {
    final aes = AesCrypt(key: Cache.cryptKey, padding: PaddingAES.pkcs7);

    AuthStore authStore = AuthStore();
    SyncStore syncStore = SyncStore();
    CryptoStore cryptoStore = CryptoStore();
    MediaStore mediaStore = MediaStore();
    RoomStore roomStore = RoomStore();
    SettingsStore settingsStore = SettingsStore();
    UserStore userStore = UserStore();

    final List<dynamic> stores = [
      authStore,
      syncStore,
      mediaStore,
      roomStore,
      cryptoStore,
      settingsStore,
      userStore,
    ];

    // Decode each store cache synchronously
    stores.forEach((store) {
      try {
        Map<String, dynamic> decodedJson = {};

        var encryptedJson;

        if (store.runtimeType == RoomStore) {
          encryptedJson = Cache.cacheRooms.get(
            store.runtimeType.toString(),
            defaultValue: null,
          );
        }

        if (store.runtimeType == CryptoStore) {
          encryptedJson = Cache.cacheCrypto.get(
            store.runtimeType.toString(),
            defaultValue: null,
          );
        }

        // pull encrypted state from cache
        encryptedJson = Cache.cacheMain.get(
          store.runtimeType.toString(),
          defaultValue: null,
        );

        // attempt to decrypt encrypted state after loaded from RAM
        if (encryptedJson != null) {
          try {
            final decryptedJson = aes.ctr.decrypt(
              enc: encryptedJson,
              iv: Cache.ivKey,
            );
            decodedJson = json.decode(decryptedJson);
          } catch (error) {
            print('[Hive Serializer DECODE] ${store.runtimeType.toString()}');
            decodedJson = {};
          }
        }

        // decryption may fail if force closed, attempt with new iv generated before close
        if (decodedJson.isEmpty) {
          try {
            // decrypt encrypted state after loaded from RAM
            final decryptedJson = aes.ctr.decrypt(
              enc: encryptedJson,
              iv: Cache.ivKeyNext,
            );
            decodedJson = json.decode(decryptedJson);
          } catch (error) {
            print('[Hive Serializer DECODE] ${store.runtimeType.toString()}');
            decodedJson = {};
          }
        }

        // if all else fails, just pass back a fresh store to avoid a crash
        if (decodedJson.isEmpty) return;

        // this stinks, but dart doesn't allow reflection for factories/contructors
        switch (store.runtimeType.toString()) {
          case 'AuthStore':
            authStore = AuthStore.fromJson(decodedJson);
            break;
          case 'SyncStore':
            syncStore = SyncStore.fromJson(decodedJson);
            break;
          case 'CryptoStore':
            cryptoStore = CryptoStore.fromJson(decodedJson);
            break;
          case 'MediaStore':
            mediaStore = MediaStore.fromJson(decodedJson);
            break;
          case 'RoomStore':
            roomStore = RoomStore.fromJson(decodedJson);
            break;
          case 'SettingsStore':
            settingsStore = SettingsStore.fromJson(decodedJson);
            break;
          case 'UserStore':
            userStore = UserStore.fromJson(decodedJson);
            break;
          default:
            break;
        }

        // decode json after decrypted and set to store
      } catch (error) {
        debugPrint('[Hive Serializer Decode] $error');
      }
    });

    return AppState(
      loading: false,
      authStore: authStore ?? AuthStore(),
      syncStore: syncStore ?? SyncStore(),
      cryptoStore: cryptoStore ?? CryptoStore(),
      roomStore: roomStore ?? RoomStore(),
      userStore: userStore ?? UserStore(),
      mediaStore: mediaStore ?? MediaStore(),
      settingsStore: settingsStore ?? SettingsStore(),
    );
  }
}
