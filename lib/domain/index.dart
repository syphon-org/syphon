import './user/model.dart';
import './chat/model.dart';

import './user/reducer.dart';
import './chat/reducer.dart';

class AppState {
  final UserStore userStore;
  final ChatStore chatStore;

  AppState({this.userStore, this.chatStore});
}

AppState appStateReducer(AppState state, action) => new AppState(
    userStore: userReducer(state.userStore, action),
    chatStore: chatReducer(state.chatStore, action));
