import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';
import 'package:redux/redux.dart';
import 'package:redux_persist/redux_persist.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:sembast/sembast.dart';
import 'package:syphon/cache/middleware.dart';
import 'package:syphon/cache/storage.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/storage/middleware.dart';
import 'package:syphon/store/alerts/middleware.dart';

import 'package:syphon/store/alerts/model.dart';
import 'package:syphon/store/auth/reducer.dart';
import 'package:syphon/store/crypto/reducer.dart';
import 'package:syphon/store/crypto/state.dart';
import 'package:syphon/store/events/reducer.dart';
import 'package:syphon/store/events/state.dart';
import 'package:syphon/store/media/reducer.dart';
import 'package:syphon/cache/serializer.dart';
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
import './search/reducer.dart';
import './search/state.dart';
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
  final EventStore eventStore;
  final UserStore userStore;
  final SyncStore syncStore;
  final CryptoStore cryptoStore;

  const AppState({
    this.loading = true,
    this.authStore = const AuthStore(),
    this.alertsStore = const AlertsStore(),
    this.syncStore = const SyncStore(),
    this.roomStore = const RoomStore(),
    this.eventStore = const EventStore(),
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
        eventStore,
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
      eventStore: eventReducer(state.eventStore, action),
      syncStore: syncReducer(state.syncStore, action),
      userStore: userReducer(state.userStore, action),
      searchStore: searchReducer(state.searchStore, action),
      settingsStore: settingsReducer(state.settingsStore, action),
      cryptoStore: cryptoReducer(state.cryptoStore, action),
    );

/// Initialize Store
/// - Hot redux state cache for top level data
Future<Store<AppState>> initStore(Database? cache, Database? storage) async {
  Map<String, dynamic> data = {};

  if (storage != null) {
    // partially load storage to memory to rehydrate cache
    data = await loadStorage(storage);
  }

  // Configure redux persist instance
  final persistor = Persistor<AppState>(
    storage: CacheStorage(cache: cache),
    serializer: CacheSerializer(cache: cache, preloaded: data),
    shouldSave: cacheMiddleware,
  );

  // Finally load persisted store
  AppState? initialState;

  try {
    initialState = await persistor.load();
  } catch (error) {
    debugPrint('[Redux Persist] $error');
  }

  final Store<AppState> store = Store<AppState>(
    appReducer,
    initialState: initialState ?? AppState(),
    middleware: [
      thunkMiddleware,
      persistor.createMiddleware(),
      storageMiddleware,
      alertMiddleware,
    ],
  );

  return Future.value(store);
}
