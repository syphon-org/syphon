import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:redux_persist/redux_persist.dart';
import 'package:sembast/sembast.dart';
import 'package:syphon/domain/auth/state.dart';
import 'package:syphon/domain/crypto/sessions/model.dart';
import 'package:syphon/domain/crypto/state.dart';
import 'package:syphon/domain/events/messages/model.dart';
import 'package:syphon/domain/events/reactions/model.dart';
import 'package:syphon/domain/events/receipts/model.dart';
import 'package:syphon/domain/events/redaction/model.dart';
import 'package:syphon/domain/events/state.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/media/state.dart';
import 'package:syphon/domain/rooms/state.dart';
import 'package:syphon/domain/settings/state.dart';
import 'package:syphon/domain/sync/state.dart';
import 'package:syphon/domain/user/state.dart';
import 'package:syphon/global/libraries/cache/index.dart';
import 'package:syphon/global/libraries/cache/threadables.dart';
import 'package:syphon/global/libraries/storage/constants.dart';
import 'package:syphon/global/print.dart';

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
            console.error('[CacheSerializer|database] $error');
          }
        } catch (error) {
          console.error(
            '[CacheSerializer|encryption] ${store.runtimeType} $error',
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
        console.error('[CacheSerializer.decode] $error');
      }
    });

    final cryptoState = cryptoStore ?? preloaded[StorageKeys.CRYPTO] as CryptoStore? ?? const CryptoStore();

    final messageSessionsLoaded = (preloaded[StorageKeys.MESSAGE_SESSIONS] ??
        <String, Map<String, List<MessageSession>>>{}) as Map<String, Map<String, List<MessageSession>>>;

    return AppState(
      loading: false,
      authStore: authStore ?? preloaded[StorageKeys.AUTH] ?? const AuthStore(),
      cryptoStore: messageSessionsLoaded.isEmpty
          ? cryptoState
          : cryptoState.copyWith(
              messageSessionsInbound: messageSessionsLoaded,
            ),
      settingsStore: preloaded[StorageKeys.SETTINGS] ?? settingsStore ?? const SettingsStore(),
      syncStore: syncStore ?? const SyncStore(),
      mediaStore: mediaStore ?? const MediaStore().copyWith(mediaCache: preloaded[StorageKeys.MEDIA]),
      roomStore: roomStore ?? const RoomStore().copyWith(rooms: preloaded[StorageKeys.ROOMS] ?? {}),
      userStore: userStore ?? const UserStore().copyWith(users: preloaded[StorageKeys.USERS] ?? {}),
      eventStore: eventStore ??
          const EventStore().copyWith(
            messages: preloaded[StorageKeys.MESSAGES] ?? <String, List<Message>>{},
            messagesDecrypted: preloaded[StorageKeys.DECRYPTED] ?? <String, List<Message>>{},
            reactions: preloaded[StorageKeys.REACTIONS] ?? <String, List<Reaction>>{},
            redactions: preloaded[StorageKeys.REDACTIONS] ?? <String, Redaction>{},
            receipts: preloaded[StorageKeys.RECEIPTS] ?? <String, Map<String, Receipt>>{},
          ),
    );
  }
}
