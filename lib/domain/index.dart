import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import './user/model.dart';
import './settings/model.dart';
import './chat/model.dart';
import './matrix/model.dart';

import './matrix/reducer.dart';
import './user/reducer.dart';
import './settings/reducer.dart';
import './chat/reducer.dart';

// https://matrix.org/docs/api/client-server/#!/User32data/register
class AppState {
  final bool loading;
  final UserStore userStore;
  final MatrixStore matrixStore;
  final SettingsStore settingsStore;
  final ChatStore chatStore;

  AppState(
      {this.loading = true,
      this.userStore = const UserStore(),
      this.matrixStore = const MatrixStore(),
      this.settingsStore = const SettingsStore(),
      this.chatStore = const ChatStore()});

  // factory AppState.loading() => AppState(loading: true);

  @override
  int get hashCode =>
      userStore.hashCode ^ chatStore.hashCode ^ loading.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppState &&
          runtimeType == other.runtimeType &&
          userStore == other.userStore &&
          chatStore == other.chatStore &&
          loading == other.loading;

  @override
  String toString() {
    return 'AppState{userStore: $userStore,' +
        'settingsStore: $settingsStore, ' +
        'chatStore: $chatStore,' +
        'matrixStore: $matrixStore,' +
        'loading: $loading}';
  }
}

AppState appReducer(AppState state, action) {
  return new AppState(
    loading: false,
    chatStore: chatReducer(state.chatStore, action),
    settingsStore: settingsReducer(state.settingsStore, action),
    userStore: userReducer(state.userStore, action),
    matrixStore: matrixReducer(state.matrixStore, action),
  );
}

final Store<AppState> store = new Store<AppState>(
  appReducer,
  initialState: AppState(),
  middleware: [thunkMiddleware],
);
