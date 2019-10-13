import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import './user/model.dart';
import './settings/model.dart';
import './chat/model.dart';

import './user/reducer.dart';
import './settings/reducer.dart';
import './chat/reducer.dart';

class AppState {
  final UserStore userStore;
  final SettingsStore settingsStore;
  final ChatStore chatStore;
  final bool loading;

  AppState(
      {this.loading = true,
      this.userStore = const UserStore(),
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
    return 'AppState{userStore: $userStore, settingsStore: $settingsStore, chatStore: $chatStore, loading: $loading}';
  }
}

AppState appReducer(AppState state, action) {
  return new AppState(
    loading: false,
    chatStore: chatReducer(state.chatStore, action),
    settingsStore: settingsReducer(state.settingsStore, action),
    userStore: userReducer(state.userStore, action),
  );
}

final Store<AppState> store = new Store<AppState>(
  appReducer,
  initialState: AppState(),
  middleware: [thunkMiddleware],
);
