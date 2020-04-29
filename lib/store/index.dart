import 'dart:io';

import 'package:Tether/store/alerts/model.dart';
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

  JsonMapper().useAdapter(JsonMapperAdapter(valueDecorators: {
    typeOf<List<User>>(): (value) => value.cast<User>(),
    typeOf<List<Event>>(): (value) => value.cast<Event>(),
    typeOf<List<Message>>(): (value) => value.cast<Message>(),
    typeOf<List<Room>>(): (value) => value.cast<Room>(),
  }));

  final persistor = Persistor<AppState>(
    storage: storageEngine,
    debug: true,
    throttleDuration: Duration(seconds: 5),
    serializer: JsonSerializer<AppState>(
      AppState.fromJson,
    ),
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
      print('${JsonMapper.toJson(settingsStore)}');
    } catch (error) {
      print('Error $error');
    }

    return {
      'loading': loading,
      'userStore': JsonMapper.toJson(userStore),
      'settingsStore': JsonMapper.toJson(settingsStore),
      'roomStore': JsonMapper.toJson(roomStore),
    };
  }

  // // Allows conversion FROM json for redux_persist
  static AppState fromJson(dynamic json) {
    if (json == null) {
      return AppState();
    }

    print('RUNNING FROM PERSIST');
    print(json['userStore']);
    print(json['settingsStore']);
    print(json['roomStore']);

    var userStore = UserStore();
    var settingsStore = SettingsStore();
    var roomStore = RoomStore();

    if (json['userStore'] != null) {
      try {
        userStore = JsonMapper.fromJson<UserStore>(
          json['userStore'],
        );
      } catch (error) {
        print('FAILED TO DESERIALIZE userStore $error');
      }
    }

    if (json['settingsStore'] != null) {
      try {
        settingsStore = JsonMapper.fromJson<SettingsStore>(
          json['settingsStore'],
        );
      } catch (error) {
        print('FAILED TO DESERIALIZE settingStore $error');
      }
    }

    if (json['roomStore'] != null) {
      try {
        print('last since ${roomStore.lastSince}');
        roomStore = JsonMapper.deserialize<RoomStore>(
          json['roomStore'],
          DeserializationOptions(template: <String, Room>{}),
        );
      } catch (error) {
        print('FAILED TO DESERIALIZE roomStore $error');
      }
    }

    return AppState(
      loading: json['loading'],
      userStore: userStore,
      settingsStore: settingsStore,
      roomStore: roomStore,
    );
  }
}
