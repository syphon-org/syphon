import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:Tether/domain/index.dart';

import './model.dart';

class SetChats {
  final List<Chat> chats;

  SetChats({this.chats});
}

class AddChat {
  final Chat chat;

  AddChat({this.chat});
}

class SetMessages {}

class SetIniting {}

class SetLoading {}

// EXAMPLE
class SetCounter {
  final int counter;

  SetCounter(this.counter);
}

void setCounterToDefault(Store<AppState> store) async {
  store.dispatch(SetCounter(5));
}

ThunkAction<AppState> incrementCounter() {
  // return (dispatch, state) =>
  return (Store<AppState> store) async {
    store.dispatch(SetCounter(store.state.chatStore.counter + 1));
  };
}

ThunkAction<AppState> setCounter(int counter) {
  // return (dispatch, state) =>
  return (Store<AppState> store) async {
    store.dispatch(SetCounter(counter));
  };
}
