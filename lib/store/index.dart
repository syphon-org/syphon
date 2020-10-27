// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:redux/redux.dart';
import 'package:redux_persist/redux_persist.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/cache/index.dart';

// Project imports:
import 'package:syphon/store/alerts/model.dart';
import 'package:syphon/store/auth/reducer.dart';
import 'package:syphon/store/crypto/reducer.dart';
import 'package:syphon/store/crypto/state.dart';
import 'package:syphon/store/media/reducer.dart';
import 'package:syphon/global/cache/serializer.dart';
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
// Future<Store> initStore() async {
//   // Configure redux persist instance
//   final persistor = Persistor<AppState>(
//     storage: MemoryStorage(),
//     serializer: CacheSerializer(),
//     throttleDuration: Duration(milliseconds: 4500),
//     shouldSave: (Store<AppState> store, dynamic action) {
//       switch (action.runtimeType) {
//         case SetSyncing:
//         case SetSynced:
//           // debugPrint('[Redux Persist] cache skip');
//           return false;
//         default:
//           // debugPrint('[Redux Persist] caching');
//           return true;
//       }
//     },
//   );

Future<Store> initStore() async {
  // Configure redux persist instance
  final persistor = Persistor<AppState>(
    storage: MemoryStorage(),
    serializer: CacheSerializer(),
    throttleDuration: Duration(milliseconds: 4500),
    shouldSave: (Store<AppState> store, dynamic action) {
      switch (action.runtimeType) {
        case SetSynced:
          if (action.synced) {
            return true;
          }
          return false;
        // debugPrint('[Redux Persist] cache skip');
        case SetSyncing:
        default:
          // debugPrint('[Redux Persist] caching');
          return false;
      }
    },
  );

  // Configure cache encryption/decryption instance
  CacheSecure.ivKey = await unlockIVKey();
  CacheSecure.ivKeyNext = await unlockIVKeyNext();
  CacheSecure.cryptKey = await unlockCryptKey();

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
