import 'dart:io';
import 'dart:typed_data';

import 'package:Tether/global/libs/hive/index.dart';
import 'package:Tether/store/alerts/model.dart';
import 'package:Tether/store/media/reducer.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:redux_persist_flutter/redux_persist_flutter.dart';

// Temporary State Store
import './alerts/model.dart';
import './search/model.dart';

// Persisted State Stores
import './media/state.dart';
import './rooms/state.dart';
import './settings/state.dart';
import './user/state.dart';

// Reducers for Stores
import './alerts/reducer.dart';
import './rooms/reducer.dart';
import './search/reducer.dart';
import './user/reducer.dart';
import './settings/reducer.dart';

import 'package:redux_persist/redux_persist.dart';

AppState appReducer(AppState state, action) {
  return AppState(
    loading: state.loading,
    alertsStore: alertsReducer(state.alertsStore, action),
    mediaStore: mediaReducer(state.mediaStore, action),
    roomStore: roomReducer(state.roomStore, action),
    userStore: userReducer(state.userStore, action),
    matrixStore: matrixReducer(state.matrixStore, action),
    settingsStore: settingsReducer(state.settingsStore, action),
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
    throttleDuration: Duration(seconds: 3),
    serializer: HiveSerializer(),
  );

  // Finally load persisted store
  var initialState;

  try {
    initialState = await persistor.load();
    print('[Redux Persist Load] persist loaded successfully');
  } catch (error) {
    print('[Redux Persist Load] error $error');
  }

  final Store<AppState> store = new Store<AppState>(
    appReducer,
    initialState: initialState ?? AppState(),
    middleware: [thunkMiddleware, persistor.createMiddleware()],
  );

  return Future.value(store);
}

class AppState {
  final bool loading;
  final AlertsStore alertsStore;
  final UserStore userStore;
  final MatrixStore matrixStore;
  final MediaStore mediaStore;
  final SettingsStore settingsStore;
  final RoomStore roomStore;

  AppState({
    this.loading = true,
    this.alertsStore = const AlertsStore(),
    this.userStore = const UserStore(),
    this.matrixStore = const MatrixStore(),
    this.mediaStore = const MediaStore(),
    this.settingsStore = const SettingsStore(),
    this.roomStore = const RoomStore(),
  });

  // Helper function to emulate { loading: action.loading, ...appState}
  AppState copyWith({bool loading}) => AppState(
        loading: loading ?? this.loading,
        alertsStore: alertsStore ?? this.alertsStore,
        userStore: userStore ?? this.userStore,
        mediaStore: mediaStore ?? this.mediaStore,
        matrixStore: matrixStore ?? this.matrixStore,
        roomStore: roomStore ?? this.roomStore,
        settingsStore: settingsStore ?? this.settingsStore,
      );

  @override
  int get hashCode =>
      loading.hashCode ^
      alertsStore.hashCode ^
      userStore.hashCode ^
      matrixStore.hashCode ^
      roomStore.hashCode ^
      settingsStore.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppState &&
          runtimeType == other.runtimeType &&
          loading == other.loading &&
          alertsStore == other.alertsStore &&
          userStore == other.userStore &&
          matrixStore == other.matrixStore &&
          roomStore == other.roomStore &&
          settingsStore == other.settingsStore;

  @override
  String toString() {
    return '{' +
        '\alertsStore: $alertsStore,' +
        '\nuserStore: $userStore,' +
        '\nmatrixStore: $matrixStore, ' +
        '\nroomStore: $roomStore,' +
        '\nsettingsStore: $settingsStore,' +
        '\n}';
  }
}

/// Serializer for a [Uint8List] state, basically pass-through
class HiveSerializer implements StateSerializer<AppState> {
  @override
  Uint8List encode(AppState state) {
    // Fail whole conversion if user fails
    Cache.hive.put(
      state.userStore.runtimeType.toString(),
      state.userStore,
    );

    try {
      Cache.hive.put(
        state.mediaStore.runtimeType.toString(),
        state.mediaStore,
      );
    } catch (error) {
      print('[Hive Storage MediaStore] - $error');
    }
    try {
      Cache.hive.put(
        state.settingsStore.runtimeType.toString(),
        state.settingsStore,
      );
    } catch (error) {
      print('[Hive Storage SettingsStore] error - $error');
    }

    try {
      Cache.hive.put(
        state.roomStore.runtimeType.toString(),
        state.roomStore,
      );
    } catch (error) {
      print('[Hive Storage RoomStore] error - $error');
    }

    // Disregard redux persist storage saving
    return null;
  }

  AppState decode(Uint8List data) {
    UserStore userStoreConverted = UserStore();
    MediaStore mediaStoreConverted = MediaStore();
    SettingsStore settingsStoreConverted = SettingsStore();
    RoomStore roomStoreConverted = RoomStore();

    userStoreConverted = Cache.hive.get(
      userStoreConverted.runtimeType.toString(),
      defaultValue: UserStore(),
    );

    try {
      mediaStoreConverted = Cache.hive.get(
        mediaStoreConverted.runtimeType.toString(),
        defaultValue: MediaStore(),
      );
    } catch (error) {
      print('[AppState.fromJson - MediaStore] error - $error');
    }

    try {
      settingsStoreConverted = Cache.hive.get(
        settingsStoreConverted.runtimeType.toString(),
        defaultValue: SettingsStore(),
      );
    } catch (error) {
      print('[AppState.fromJson - SettingsStore] error $error');
    }

    try {
      roomStoreConverted = Cache.hive.get(
        roomStoreConverted.runtimeType.toString(),
        defaultValue: RoomStore(),
      );
    } catch (error) {
      print('[AppState.fromJson - roomStoreConverted] error $error');
    }

    return AppState(
      loading: false,
      userStore: userStoreConverted,
      settingsStore: settingsStoreConverted,
      roomStore: roomStoreConverted,
      mediaStore: mediaStoreConverted,
    );
  }
}
