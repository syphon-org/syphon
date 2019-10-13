import './model.dart';
import './actions.dart';

ChatStore chatReducer([ChatStore state = const ChatStore(), dynamic action]) {
  print('Chat Reducer $action');
  switch (action.runtimeType) {
    case SetChats:
      return new ChatStore(
        initing: false,
        loading: false,
        counter: 0,
        chats: action.chats,
      );
    case SetMessages:
      return new ChatStore(
        initing: false,
        loading: false,
        counter: 0,
        chats: action.chats,
      );
    case SetIniting:
      return new ChatStore(
        initing: false,
        loading: false,
        counter: 0,
        chats: action.chats,
      );
    case SetCounter:
      return new ChatStore(
        initing: state.initing,
        loading: state.loading,
        counter: action.counter,
        chats: state.chats,
      );
    default:
      return state;
  }
}
