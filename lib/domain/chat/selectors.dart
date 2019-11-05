import 'package:Tether/domain/index.dart';

import './model.dart';

// int counter(AppState state) => state.chatStore.counter;

int counter(AppState state) {
  return state.chatStore.counter;
}

List<Chat> chats(AppState state) {
  return state.chatStore.chats;
}
