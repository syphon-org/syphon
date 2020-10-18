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
import 'search/state.dart';
import './search/reducer.dart';
import './settings/reducer.dart';
import './settings/state.dart';

// Temporary State Store

// Persisted State Stores

// Reducers for Stores

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

AppState appReducer(AppState state, action) {
  return AppState(
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
}

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
  final persistor = Persistor<AppState>(
    storage: MemoryStorage(),
    serializer: HiveSerializer(),
    throttleDuration: Duration(seconds: 6),
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
 * Hive Serializer
 * 
 * Only reliance on redux is when too save state
 */
class HiveSerializer implements StateSerializer<AppState> {
  @override
  Uint8List encode(AppState state) {
    // Fail whole conversion if user fails

    // final stores = [
    //   state.authStore,
    //   state.syncStore,
    //   state.cryptoStore,
    //   state.roomStore,
    //   state.mediaStore,
    //   state.settingsStore,
    //   state.userStore,
    // ];

    // Cache each store asyncronously
    // Future.wait(stores.map((store) async {
    //   try {
    //     Cache.state.put(
    //       store.runtimeType.toString(),
    //       json.encode(store),
    //     );
    //   } catch (error) {
    //     debugPrint('[Hive Serializer Encode] $error');
    //   }
    // }));

    try {
      Cache.state.put(
        state.authStore.runtimeType.toString(),
        json.encode(state.authStore),
      );
    } catch (error) {
      debugPrint('[Hive Serializer Encode] $error');
    }

    try {
      Cache.state.put(
        state.syncStore.runtimeType.toString(),
        state.syncStore,
      );
      // debugPrint('[Hive Storage] caching syncStore');
    } catch (error) {
      debugPrint('[Hive Serializer Encode] $error');
    }

    try {
      Cache.stateRooms.put(
        state.roomStore.runtimeType.toString(),
        state.roomStore,
      );
      // debugPrint('[Hive Storage] caching roomStore');
    } catch (error) {
      debugPrint('[Hive Serializer Encode] $error');
    }

    try {
      Cache.state.put(
        state.mediaStore.runtimeType.toString(),
        state.mediaStore,
      );
      // debugPrint('[Hive Storage] caching mediaStore');
    } catch (error) {
      debugPrint('[Hive Serializer Encode] $error');
    }

    try {
      Cache.state.put(
        state.settingsStore.runtimeType.toString(),
        state.settingsStore,
      );
      // debugPrint('[Hive Storage] caching settingsStore');
    } catch (error) {
      debugPrint('[Hive Serializer Encode] $error');
    }

    try {
      Cache.state.put(
        state.cryptoStore.runtimeType.toString(),
        state.cryptoStore,
      );
      // debugPrint('[Hive Storage] caching cryptoStore');
    } catch (error) {
      debugPrint('[Hive Serializer Encode] $error');
    }

    // Disregard redux persist storage saving
    return null;
  }

  AppState decode(Uint8List data) {
    AuthStore authStoreConverted = AuthStore();
    SyncStore syncStoreConverted = SyncStore();
    CryptoStore cryptoStoreConverted = CryptoStore();
    MediaStore mediaStoreConverted = MediaStore();
    RoomStore roomStoreConverted = RoomStore();
    SettingsStore settingsStoreConverted = SettingsStore();
    UserStore userStore = UserStore();

    // final types = [
    //   AuthStore,
    //   SyncStore,
    //   CryptoStore,
    //   RoomStore,
    //   MediaStore,
    //   SettingsStore,
    //   UserStore,
    // ];

    // final stores = [
    //   authStoreConverted,
    //   syncStoreConverted,
    //   cryptoStoreConverted,
    //   mediaStoreConverted,
    //   roomStoreConverted,
    //   settingsStoreConverted,
    //   userStore,
    // ];

    // // Decode each store cache synchronously
    // types.forEach((type) {
    //   try {
    //     final index = types.indexOf(type);
    //     final dynamic store = stores[index];
    //     stores[index] = store.fromJson(json.decode(
    //       Cache.state.get(
    //         store.runtimeType.toString(),
    //         defaultValue: store[index](),
    //       ),
    //     ));
    //   } catch (error) {
    //     debugPrint('[Hive Serializer Decode] $error');
    //   }
    // });

    try {
      authStoreConverted = AuthStore.fromJson(
        json.decode(
          Cache.state.get(
            authStoreConverted.runtimeType.toString(),
            defaultValue: AuthStore(),
          ),
        ),
      );
    } catch (error) {
      debugPrint('[Hive Serializer Decode] $error');
    }

    try {
      syncStoreConverted = Cache.state.get(
        syncStoreConverted.runtimeType.toString(),
        defaultValue: SyncStore(),
      );
    } catch (error) {
      debugPrint('[Hive Serializer Decode] $error');
    }

    try {
      cryptoStoreConverted = Cache.state.get(
        cryptoStoreConverted.runtimeType.toString(),
        defaultValue: CryptoStore(),
      );
    } catch (error) {
      debugPrint('[Hive Serializer Decode] $error');
    }

    try {
      roomStoreConverted = Cache.stateRooms.get(
        roomStoreConverted.runtimeType.toString(),
        defaultValue: RoomStore(),
      );
    } catch (error) {
      debugPrint('[Hive Serializer Decode] $error');
    }

    try {
      mediaStoreConverted = Cache.state.get(
        mediaStoreConverted.runtimeType.toString(),
        defaultValue: MediaStore(),
      );
    } catch (error) {
      debugPrint('[Hive Serializer Decode] $error');
    }

    try {
      settingsStoreConverted = Cache.state.get(
        settingsStoreConverted.runtimeType.toString(),
        defaultValue: SettingsStore(),
      );
    } catch (error) {
      debugPrint('[Hive Serializer Decode] $error');
    }

    return AppState(
      loading: false,
      authStore: authStoreConverted,
      syncStore: syncStoreConverted,
      cryptoStore: cryptoStoreConverted,
      roomStore: roomStoreConverted,
      userStore: userStore, // not cached
      mediaStore: mediaStoreConverted,
      settingsStore: settingsStoreConverted,
    );
  }
}
