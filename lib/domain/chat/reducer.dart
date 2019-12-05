import './model.dart';
import './actions.dart';

ChatStore chatReducer([ChatStore state = const ChatStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetLoading:
      return state.copyWith(loading: action.loading);
    case SetSyncing:
      return state.copyWith(syncing: action.syncing);
    case SetChatObserver:
      return state.copyWith(chatObserver: action.chatObserver);
    case SetChats:
      return state.copyWith(chats: action.chats);
    case AddChat:
      List<Chat> chats = List<Chat>.from(state.chats);
      chats.add(action.chat);
      return state.copyWith(chats: chats);
    default:
      return state;
  }
}
