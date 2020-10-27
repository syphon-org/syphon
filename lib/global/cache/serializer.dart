// Dart imports:
import 'dart:convert';
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:redux_persist/redux_persist.dart';
import 'package:steel_crypt/steel_crypt.dart';
import 'package:syphon/global/cache/index.dart';
import 'package:syphon/global/cache/threadables.dart';
import 'package:syphon/global/libs/hive/encoder.dart';
import 'package:syphon/global/libs/hive/index.dart';

// Project imports:
import 'package:syphon/store/crypto/state.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/sync/state.dart';
import 'package:syphon/store/user/state.dart';
import 'package:syphon/store/auth/state.dart';
import 'package:syphon/store/media/state.dart';
import 'package:syphon/store/rooms/state.dart';
import 'package:syphon/store/settings/state.dart';

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
      // // create a new IV for the encrypted cache
      CacheSecure.ivKey = createIVKey();
      // // backup the IV in case the app is force closed before caching finishes
      await saveIVKeyNext(CacheSecure.ivKey);

      // run through all redux stores for encryption and encoding
      await Future.wait(stores.map((store) async {
        try {
          var jsonEncoded;
          var jsonEncrypted;

          // encode the store contents to json
          // HACK: unable to pass both listed stores direct to an isolate
          // final sensitiveStorage = [AuthStore, SyncStore, CryptoStore];
          // if (!sensitiveStorage.contains(store.runtimeType)) {
          //   jsonEncoded = await compute(jsonEncode, store);
          // } else {
          jsonEncoded = json.encode(store);
          // }

          // encrypt the store contents previously converted to json
          jsonEncrypted = await compute(encryptJsonBackground, {
            'ivKey': CacheSecure.ivKey,
            'cryptKey': CacheSecure.cryptKey,
            'type': store.runtimeType.toString(),
            'json': jsonEncoded,
          });

          // cache redux store to main cache storage
          // caching room and crypto stores with additional hive level error handling
          switch (store.runtimeType) {
            case RoomStore:
              await CacheSecure.cacheRooms.put(
                store.runtimeType.toString(),
                jsonEncrypted,
              );
              break;
            case CryptoStore:
              await CacheSecure.cacheCrypto.put(
                store.runtimeType.toString(),
                jsonEncrypted,
              );
              break;
            default:
              await CacheSecure.cacheMain.put(
                store.runtimeType.toString(),
                jsonEncrypted,
              );
              break;
          }
        } catch (error) {
          debugPrint(
            '[Cache Serializer Encode] $error',
          );
        }
      }));

      // Rotate encryption for the next save
      await saveIVKey(CacheSecure.ivKey);
    });

    // Disregard redux persist storage saving
    return null;
  }

  AppState decode(Uint8List data) {
    final aes = AesCrypt(key: CacheSecure.cryptKey, padding: PaddingAES.pkcs7);

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

    // TODO: remove after most have upgraded to 0.1.4/0.1.5
    if ((Cache.state != null || Cache.stateRooms != null) &&
        Cache.migration == null) {
      debugPrint(
        '[Legacy Cache Found] ***** FOUND ****** loading and removing cache',
      );
      final legacyAppState = LegacyEncoder.decodeHive();
      deleteLegacyStorage();
      return legacyAppState;
    }

    // decode each store cache synchronously
    stores.forEach((store) {
      try {
        Map<String, dynamic> decodedJson = {};

        var encryptedJson;

        // fetch from main cache storage
        // fetching room and crypto store has additional hive level error handling
        switch (store.runtimeType) {
          case RoomStore:
            encryptedJson = CacheSecure.cacheRooms.get(
              store.runtimeType.toString(),
              defaultValue: null,
            );
            break;
          case CryptoStore:
            encryptedJson = CacheSecure.cacheCrypto.get(
              store.runtimeType.toString(),
              defaultValue: null,
            );
            break;
          default:
            encryptedJson = CacheSecure.cacheMain.get(
              store.runtimeType.toString(),
              defaultValue: null,
            );
            break;
        }

        // attempt to decrypt encrypted state after loaded from RAM
        if (encryptedJson != null) {
          try {
            final decryptedJson = aes.ctr.decrypt(
              enc: encryptedJson,
              iv: CacheSecure.ivKey,
            );
            decodedJson = json.decode(decryptedJson);
          } catch (error) {
            debugPrint('[Cache Serializer Decode] $error');
            decodedJson = {};
          }
        }

        // decryption may fail if force closed, attempt with new iv generated before close
        if (decodedJson.isEmpty) {
          try {
            // decrypt encrypted state after loaded from RAM
            final decryptedJson = aes.ctr.decrypt(
              enc: encryptedJson,
              iv: CacheSecure.ivKeyNext,
            );
            decodedJson = json.decode(decryptedJson);
          } catch (error) {
            debugPrint('[Cache Serializer Decode] $error');
            decodedJson = {};
          }
        }

        // if all else fails, just pass back a fresh store to avoid a crash
        if (decodedJson.isEmpty) return;

        // this stinks, but dart doesn't allow reflection for factories/contructors
        switch (store.runtimeType) {
          case AuthStore:
            authStore = AuthStore.fromJson(decodedJson);
            break;
          case SyncStore:
            syncStore = SyncStore.fromJson(decodedJson);
            break;
          case CryptoStore:
            cryptoStore = CryptoStore.fromJson(decodedJson);
            break;
          case MediaStore:
            mediaStore = MediaStore.fromJson(decodedJson);
            break;
          case RoomStore:
            roomStore = RoomStore.fromJson(decodedJson);
            break;
          case SettingsStore:
            settingsStore = SettingsStore.fromJson(decodedJson);
            break;
          case UserStore:
            userStore = UserStore.fromJson(decodedJson);
            break;
          default:
            break;
        }
      } catch (error) {
        debugPrint('[Cache Serializer Decode] $error');
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
