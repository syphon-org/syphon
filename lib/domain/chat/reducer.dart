import './model.dart';
import './actions.dart';

ChatStore chatReducer([ChatStore state = const ChatStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetChats:
      return ChatStore(
        initing: state.initing,
        loading: state.loading,
        counter: state.counter,
        chats: action.chats,
      );
    case SetMessages:
      return ChatStore(
        initing: false,
        loading: false,
        counter: 0,
        chats: action.chats,
      );
    case SetIniting:
      return ChatStore(
        initing: false,
        loading: false,
        counter: 0,
        chats: action.chats,
      );
    case AddChat:
      List<Chat> chats = List<Chat>.from(state.chats);
      chats.add(action.chat);

      return ChatStore(
          initing: state.initing,
          loading: state.loading,
          counter: state.counter,
          chats: chats);

    case SetCounter:
      return ChatStore(
        initing: state.initing,
        loading: state.loading,
        counter: action.counter,
        chats: state.chats,
      );
    default:
      return state;
  }
}
