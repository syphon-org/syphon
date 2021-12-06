import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:redux_persist/redux_persist.dart';
import 'package:sembast/sembast.dart';
import 'package:syphon/cache/index.dart';
import 'package:syphon/cache/threadables.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/store/auth/state.dart';
import 'package:syphon/store/crypto/state.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/receipts/model.dart';
import 'package:syphon/store/events/redaction/model.dart';
import 'package:syphon/store/events/state.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/media/state.dart';
import 'package:syphon/store/rooms/state.dart';
import 'package:syphon/store/settings/state.dart';
import 'package:syphon/store/sync/state.dart';
import 'package:syphon/store/user/state.dart';

///
/// Cache Serializer
///
/// Handles serialization, encryption, and storage for caching redux stores
///
class CacheSerializer implements StateSerializer<AppState> {
  final Database? cache;
  final Map<String, dynamic> preloaded;

  CacheSerializer({this.cache, this.preloaded = const {}});

  @override
  Uint8List? encode(AppState state) {
    final List<Object> stores = [
      state.authStore,
      state.syncStore,
      state.cryptoStore,
      state.roomStore,
    ];

    // Queue up a cache saving will wait
    // if the previously schedule task has not finished
    Future.microtask(() async {
      // run through all redux stores for encryption and encoding
      await Future.wait(stores.map((store) async {
        try {
          final type = store.runtimeType.toString();
          final json = jsonEncode(store);

          // encrypt the store contents
          final jsonEncrypted = await compute(
            encryptJsonBackground,
            {
              'type': type,
              'json': json,
              'cacheKey': Cache.cacheKey,
            },
            debugLabel: 'encryptJsonBackground',
          );

          try {
            final storeRef = StoreRef<String, String>.main();
            await storeRef.record(type).put(cache!, jsonEncrypted);
          } catch (error) {
            printError('[CacheSerializer|database] $error');
          }
        } catch (error) {
          printError(
            '[CacheSerializer|encryption] ${store.runtimeType.toString()} $error',
          );
        }
      }));

      return Future.value(null);
    });

    // Disregard redux persist storage saving
    return null;
  }

  @override
  AppState decode(Uint8List? data) {
    AuthStore? authStore;
    SyncStore? syncStore;
    UserStore? userStore;
    CryptoStore? cryptoStore;
    MediaStore? mediaStore;
    RoomStore? roomStore;
    EventStore? eventStore;
    SettingsStore? settingsStore;

    // Load stores previously fetched from cache,
    // mutable global due to redux_presist not extendable beyond Uint8List
    final stores = Cache.cacheStores;

    // decode each store cache synchronously
    stores.forEach((type, store) {
      try {
        // if all else fails, just pass back a fresh store to avoid a crash
        if (store == null || store.isEmpty) return;

        // this stinks, but dart doesn't allow reflection for factories/contructors
        switch (type) {
          case 'AuthStore':
            authStore = AuthStore.fromJson(store as Map<String, dynamic>);
            break;
          case 'SyncStore':
            syncStore = SyncStore.fromJson(store as Map<String, dynamic>);
            break;
          case 'CryptoStore':
            cryptoStore = CryptoStore.fromJson(store as Map<String, dynamic>);
            break;
          case 'MediaStore':
            mediaStore = MediaStore.fromJson(store as Map<String, dynamic>);
            break;
          case 'SettingsStore':
            settingsStore = SettingsStore.fromJson(store as Map<String, dynamic>);
            break;
          case 'UserStore':
            userStore = UserStore.fromJson(store as Map<String, dynamic>);
            break;
          case 'EventStore':
            eventStore = EventStore.fromJson(store as Map<String, dynamic>);
            break;
          case 'RoomStore':
            roomStore = RoomStore.fromJson(store as Map<String, dynamic>);
            break;
          default:
            break;
        }
      } catch (error) {
        printError('[CacheSerializer.decode] $error');
      }
    });

    return AppState(
      loading: false,
      authStore: authStore ?? preloaded[StorageKeys.AUTH] ?? AuthStore(),
      cryptoStore: cryptoStore ?? preloaded[StorageKeys.CRYPTO] ?? CryptoStore(),
      settingsStore: preloaded[StorageKeys.SETTINGS] ?? settingsStore ?? SettingsStore(),
      syncStore: syncStore ?? SyncStore(),
      mediaStore: mediaStore ?? MediaStore().copyWith(mediaCache: preloaded[StorageKeys.MEDIA]),
      roomStore: roomStore ?? RoomStore().copyWith(rooms: preloaded[StorageKeys.ROOMS] ?? {}),
      userStore: userStore ?? UserStore().copyWith(users: preloaded[StorageKeys.USERS] ?? {}),
      eventStore: eventStore ??
          EventStore().copyWith(
            messages: preloaded[StorageKeys.MESSAGES] ?? <String, List<Message>>{},
            messagesDecrypted: preloaded[StorageKeys.DECRYPTED] ?? <String, List<Message>>{},
            reactions: preloaded[StorageKeys.REACTIONS] ?? <String, List<Reaction>>{},
            redactions: preloaded[StorageKeys.REDACTIONS] ?? <String, Redaction>{},
            receipts: preloaded[StorageKeys.RECEIPTS] ?? <String, Map<String, Receipt>>{},
          ),
    );
  }
}
