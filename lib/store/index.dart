import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syphon/global/libs/hive/index.dart';
import 'package:syphon/store/alerts/model.dart';
import 'package:syphon/store/auth/reducer.dart';
import 'package:syphon/store/crypto/reducer.dart';
import 'package:syphon/store/crypto/state.dart';
import 'package:syphon/store/media/reducer.dart';
import 'package:syphon/store/sync/actions.dart';
import 'package:syphon/store/sync/reducer.dart';
import 'package:syphon/store/sync/state.dart';
import 'package:equatable/equatable.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

// Temporary State Store
import './alerts/model.dart';
import './search/model.dart';

// Persisted State Stores
import './media/state.dart';
import './rooms/state.dart';
import './settings/state.dart';
import './auth/state.dart';

// Reducers for Stores
import './alerts/reducer.dart';
import './rooms/reducer.dart';
import './search/reducer.dart';
import './settings/reducer.dart';

import 'package:redux_persist/redux_persist.dart';

class AppState extends Equatable {
  final bool loading;
  final AuthStore authStore;
  final AlertsStore alertsStore;
  final SearchStore searchStore;
  final MediaStore mediaStore;
  final SettingsStore settingsStore;
  final RoomStore roomStore;
  final SyncStore syncStore;
  final CryptoStore cryptoStore;

  AppState({
    this.loading = true,
    this.authStore = const AuthStore(),
    this.alertsStore = const AlertsStore(),
    this.searchStore = const SearchStore(),
    this.mediaStore = const MediaStore(),
    this.settingsStore = const SettingsStore(),
    this.roomStore = const RoomStore(),
    this.syncStore = const SyncStore(),
    this.cryptoStore = const CryptoStore(),
  });

  @override
  List<Object> get props => [
        loading,
        alertsStore,
        authStore,
        searchStore,
        roomStore,
        settingsStore,
        syncStore,
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
    searchStore: matrixReducer(state.searchStore, action),
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
    throttleDuration: Duration(seconds: 5),
    shouldSave: (Store<AppState> store, dynamic action) {
      switch (action.runtimeType) {
        case SetSyncing:
        case SetSynced:
          debugPrint('[Redux Persist] cache skip');
          return false;
        default:
          debugPrint('[Redux Persist] caching');
          return true;
      }
    },
  );

  // Finally load persisted store
  var initialState;

  try {
    initialState = await persistor.load();
    debugPrint('[Redux Persist] persist loaded successfully');
  } catch (error) {
    debugPrint('[Redux Persist] error $error');
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
    Cache.state.put(
      state.authStore.runtimeType.toString(),
      state.authStore,
    );

    try {
      Cache.state.put(
        state.syncStore.runtimeType.toString(),
        state.syncStore,
      );
    } catch (error) {
      print('[Hive Storage SyncStore] error - $error');
    }

    try {
      Cache.state.put(
        state.cryptoStore.runtimeType.toString(),
        state.cryptoStore,
      );
    } catch (error) {
      print('[Hive Storage CryptoStore] error - $error');
    }

    try {
      Cache.state.put(
        state.roomStore.runtimeType.toString(),
        state.roomStore,
      );
    } catch (error) {
      print('[Hive Storage RoomStore] error - $error');
    }

    try {
      Cache.state.put(
        state.mediaStore.runtimeType.toString(),
        state.mediaStore,
      );
    } catch (error) {
      print('[Hive Storage MediaStore] - $error');
    }

    try {
      Cache.state.put(
        state.settingsStore.runtimeType.toString(),
        state.settingsStore,
      );
    } catch (error) {
      print('[Hive Storage SettingsStore] error - $error');
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

    authStoreConverted = Cache.state.get(
      authStoreConverted.runtimeType.toString(),
      defaultValue: AuthStore(),
    );

    try {
      syncStoreConverted = Cache.state.get(
        syncStoreConverted.runtimeType.toString(),
        defaultValue: SyncStore(),
      );
    } catch (error) {
      print('[AppState.fromJson - roomStoreConverted] error $error');
    }

    try {
      cryptoStoreConverted = Cache.state.get(
        cryptoStoreConverted.runtimeType.toString(),
        defaultValue: CryptoStore(),
      );
    } catch (error) {
      print('[AppState.fromJson - CryptoStoreConverted] error $error');
    }

    try {
      roomStoreConverted = Cache.state.get(
        roomStoreConverted.runtimeType.toString(),
        defaultValue: RoomStore(),
      );
    } catch (error) {
      print('[AppState.fromJson - roomStoreConverted] error $error');
    }

    try {
      mediaStoreConverted = Cache.state.get(
        mediaStoreConverted.runtimeType.toString(),
        defaultValue: MediaStore(),
      );
    } catch (error) {
      print('[AppState.fromJson - MediaStore] error - $error');
    }

    try {
      settingsStoreConverted = Cache.state.get(
        settingsStoreConverted.runtimeType.toString(),
        defaultValue: SettingsStore(),
      );
    } catch (error) {
      print('[AppState.fromJson - SettingsStore] error $error');
    }

    return AppState(
      loading: false,
      authStore: authStoreConverted,
      syncStore: syncStoreConverted,
      cryptoStore: cryptoStoreConverted,
      roomStore: roomStoreConverted,
      mediaStore: mediaStoreConverted,
      settingsStore: settingsStoreConverted,
    );
  }
}
