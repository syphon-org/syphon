// Dart imports:
import 'dart:convert';
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:redux/redux.dart';
import 'package:redux_persist/redux_persist.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:steel_crypt/steel_crypt.dart';
import 'package:syphon/global/algos.dart';

// Project imports:
import 'package:syphon/global/libs/hive/index.dart';
import 'package:syphon/store/alerts/model.dart';
import 'package:syphon/store/auth/reducer.dart';
import 'package:syphon/store/crypto/reducer.dart';
import 'package:syphon/store/crypto/state.dart';
import 'package:syphon/store/media/reducer.dart';
import 'package:syphon/store/sync/actions.dart';
import 'package:syphon/store/sync/reducer.dart';
import 'package:syphon/store/sync/state.dart';
import 'package:syphon/store/user/reducer.dart';
import 'package:syphon/store/user/state.dart';
import './alerts/model.dart';
import './alerts/reducer.dart';
import './auth/state.dart';
import './media/state.dart';
import './rooms/reducer.dart';
import './rooms/state.dart';
import './search/state.dart';
import './search/reducer.dart';
import './settings/reducer.dart';
import './settings/state.dart';

class AppState extends Equatable {
  final bool loading;
  final AuthStore authStore;
  final AlertsStore alertsStore;
  final SearchStore searchStore;
  final MediaStore mediaStore;
  final SettingsStore settingsStore;
  final RoomStore roomStore;
  final UserStore userStore;
  final SyncStore syncStore;
  final CryptoStore cryptoStore;

  AppState({
    this.loading = true,
    this.authStore = const AuthStore(),
    this.alertsStore = const AlertsStore(),
    this.syncStore = const SyncStore(),
    this.roomStore = const RoomStore(),
    this.userStore = const UserStore(),
    this.mediaStore = const MediaStore(),
    this.searchStore = const SearchStore(),
    this.settingsStore = const SettingsStore(),
    this.cryptoStore = const CryptoStore(),
  });

  @override
  List<Object> get props => [
        loading,
        alertsStore,
        authStore,
        syncStore,
        roomStore,
        userStore,
        mediaStore,
        searchStore,
        settingsStore,
        cryptoStore,
      ];
}

AppState appReducer(AppState state, action) => AppState(
      loading: state.loading,
      authStore: authReducer(state.authStore, action),
      alertsStore: alertsReducer(state.alertsStore, action),
      mediaStore: mediaReducer(state.mediaStore, action),
      roomStore: roomReducer(state.roomStore, action),
      syncStore: syncReducer(state.syncStore, action),
      userStore: userReducer(state.userStore, action),
      searchStore: searchReducer(state.searchStore, action),
      settingsStore: settingsReducer(state.settingsStore, action),
      cryptoStore: cryptoReducer(state.cryptoStore, action),
    );

/**
 * Initialize Store
 * - Hot redux state cache for top level data
 * * Consider still using hive here
 * 
 * PLEASE NOTE redux persist manages when the store
 * should persist and if it can, not where it's persisting too
 * this is why the "storage: MemoryStore()" property is set and
 * the Hive Serializer has been impliemented
 */
Future<Store> initStore() async {
  // Configure redux persist instance
  final persistor = Persistor<AppState>(
    storage: MemoryStorage(),
    serializer: CacheSerializer(),
    throttleDuration: Duration(milliseconds: 2500),
    shouldSave: (Store<AppState> store, dynamic action) {
      switch (action.runtimeType) {
        case SetSyncing:
        case SetSynced:
          // debugPrint('[Redux Persist] cache skip');
          return false;
        default:
          // debugPrint('[Redux Persist] caching');
          return true;
      }
    },
  );

  // Configure cache encryption/decryption instance
  Cache.ivKey = await unlockIVKey();
  Cache.ivKeyNext = await unlockIVKeyNext();
  Cache.cryptKey = await unlockCryptKey();

  // Finally load persisted store
  var initialState;

  try {
    initialState = await persistor.load();
    // debugPrint('[Redux Persist] persist loaded successfully');
  } catch (error) {
    debugPrint('[Redux Persist] $error');
  }

  final Store<AppState> store = Store<AppState>(
    appReducer,
    initialState: initialState ?? AppState(),
    middleware: [thunkMiddleware, persistor.createMiddleware()],
  );

  return Future.value(store);
}

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
      // create a new IV for the encrypted cache
      Cache.ivKey = createIVKey();
      // backup the IV in case the app is force closed before caching finishes
      await saveIVKeyNext(Cache.ivKey);

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

      // Rotate encryption for the next save
      await saveIVKey(Cache.ivKey);
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
      cryptoStore,
      mediaStore,
      roomStore,
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
          }
        }

        // decryption may fail if force closed, attempt with new iv generated before close
        if (decodedJson == null) {
          try {
            // decrypt encrypted state after loaded from RAM
            final decryptedJson = aes.ctr.decrypt(
              enc: encryptedJson,
              iv: Cache.ivKeyNext,
            );
            decodedJson = json.decode(decryptedJson);
          } catch (error) {
            print('[Hive Serializer DECODE] ${store.runtimeType.toString()}');
          }
        }

        print(
          '[Hive Serializer DECODE] ${store.runtimeType.toString()}',
        );
        // this stinks, but dart doesn't allow reflection for factories/contructors
        switch (store.runtimeType.toString()) {
          case 'AuthStore':
            authStore = AuthStore.fromJson(decodedJson);
            break;
          case 'SyncStore':
            syncStore = SyncStore.fromJson(decodedJson);
            break;
          // case 'CryptoStore':
          //   cryptoStore = CryptoStore.fromJson(decodedJson);
          //   break;
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
      userStore: userStore ?? UserStore(), // not cached
      mediaStore: mediaStore ?? MediaStore(),
      settingsStore: settingsStore ?? SettingsStore(),
    );
  }
}
