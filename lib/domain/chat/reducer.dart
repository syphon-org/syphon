import './model.dart';

enum Actions { setChats, setChatMessages, setInitializing, setLoading }

ChatStore chatReducer(ChatStore state, action) {
  switch (action.type) {
    case Actions.setChats:
      return new ChatStore(
        initing: false,
        loading: false,
        chats: action.chats,
      );
    case Actions.setChatMessages:
      return new ChatStore(
        initing: false,
        loading: false,
        chats: action.chats,
      );
    case Actions.setLoading:
      return new ChatStore(
        initing: false,
        loading: false,
        chats: action.chats,
      );
    default:
      return state;
  }
}
