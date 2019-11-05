import 'dart:math';

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

ThunkAction<AppState> addChat() {
  // return (dispatch, state) =>
  return (Store<AppState> store) async {
    var chatId = Random.secure().nextInt(10000000).toString();

    store.dispatch(AddChat(
        chat: Chat(
            chatId: chatId,
            title: 'chat-$chatId',
            messages: [],
            syncing: false)));
  };
}

// *** EXAMPLES ***
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
