import 'dart:collection';
import 'dart:io';

import 'package:Tether/store/alerts/model.dart';
import 'package:Tether/store/settings/chat-settings/model.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:redux_persist_flutter/redux_persist_flutter.dart';

import './alerts/model.dart';
import './user/model.dart';
import './settings/model.dart';
import './rooms/model.dart';
import './rooms/room/model.dart';
import './rooms/events/model.dart';
import './search/model.dart';

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
 */
Future<Store> initStore() async {
  var storageEngine;

  if (Platform.isIOS || Platform.isAndroid) {
    storageEngine = FlutterStorage();
  }

  if (Platform.isMacOS) {
    final storageLocation = await File('cache').create().then(
          (value) => value.writeAsString(
            '{}',
            flush: true,
          ),
        );
    storageEngine = FileStorage(storageLocation);
  }

  // TODO: this is causing a small blip in rendering
  final persistor = Persistor<AppState>(
    storage: storageEngine,
    // debug: true,
    throttleDuration: Duration(seconds: 5),
    serializer: JsonSerializer<AppState>(
      AppState.fromJson,
    ),
  );

  // Load available json list decorators
  JsonMapper.registerValueDecorator<List<User>>(
    (value) => value.cast<User>(),
  );
  JsonMapper.registerValueDecorator<List<Event>>(
    (value) => value.cast<Event>(),
  );
  JsonMapper.registerValueDecorator<List<Message>>(
    (value) => value.cast<Message>(),
  );
  JsonMapper.registerValueDecorator<List<Room>>(
    (value) => value.cast<Room>(),
  );
  JsonMapper.registerValueDecorator<Map<String, ChatSetting>>(
    (value) => value.cast<String, ChatSetting>(),
  );
  JsonMapper.registerValueDecorator<Map<String, Room>>(
    (value) => value.cast<String, Room>(),
  );

  // Finally load persisted store
  var initialState;
  try {
    initialState = await persistor.load();
    print('[initStore] persist loaded successfully');
  } catch (error) {
    print('[initStore] error $error');
  }

  final Store<AppState> store = new Store<AppState>(
    appReducer,
    initialState: initialState ?? AppState(),
    middleware: [thunkMiddleware, persistor.createMiddleware()],
  );

  return Future.value(store);
}

// https://matrix.org/docs/api/client-server/#!/User32data/register
class AppState {
  final bool loading;
  final AlertsStore alertsStore;
  final UserStore userStore;
  final MatrixStore matrixStore;
  final SettingsStore settingsStore;
  final RoomStore roomStore;

  AppState(
      {this.loading = true,
      this.alertsStore = const AlertsStore(),
      this.userStore = const UserStore(),
      this.matrixStore = const MatrixStore(),
      this.settingsStore = const SettingsStore(),
      this.roomStore = const RoomStore()});

  // Helper function to emulate { loading: action.loading, ...appState}
  AppState copyWith({bool loading}) => AppState(
        loading: loading ?? this.loading,
        alertsStore: alertsStore ?? this.alertsStore,
        userStore: userStore ?? this.userStore,
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

  // Allows conversion TO json for redux_persist
  dynamic toJson() {
    try {
      // print(JsonMapper.toJson(settingsStore));
      if (settingsStore.customChatSettings != null) {
        var testingAgain = JsonMapper.toJson(
            settingsStore.customChatSettings.values.elementAt(0));
        print(
          '[settingsStore customChatSettings.values toJson] ${testingAgain}',
        );
        var testing = JsonMapper.toMap(settingsStore.customChatSettings);
        print(
          '[settings store fromMap customChatSettings] ${testing}',
        );
      }
    } catch (error) {
      print('[AppState.toJson] error - $error');
    }

    return {
      'loading': loading,
      'userStore': JsonMapper.toJson(userStore),
      'settingsStore': JsonMapper.toJson(settingsStore),
      'roomStore': roomStore.toJson()
    };
  }

  /* 
    Allows conversion FROM json for redux_persist
    prevents one store from breaking every persist
  */
  static AppState fromJson(dynamic json) {
    if (json == null) {
      return AppState();
    }

    UserStore userStoreConverted = UserStore();
    SettingsStore settingsStoreConverted = SettingsStore();
    RoomStore roomStoreConverted = RoomStore();

    try {
      userStoreConverted = JsonMapper.fromJson<UserStore>(
        json['userStore'],
      );
    } catch (error) {
      print('[AppState.fromJson] userStoreConverted error $error');
    }

    try {
      settingsStoreConverted = JsonMapper.fromJson<SettingsStore>(
        json['settingsStore'],
      );
    } catch (error) {
      print('[AppState.fromJson] settingsStoreConverted error $error');
    }

    try {
      roomStoreConverted = RoomStore.fromJson(json['roomStore']);
    } catch (error) {
      print('[AppState.fromJson] roomStoreConverted error $error');
    }

    return AppState(
      loading: json['loading'],
      userStore: userStoreConverted,
      settingsStore: settingsStoreConverted,
      roomStore: roomStoreConverted,
    );
  }
}
