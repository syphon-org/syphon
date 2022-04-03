import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/store/settings/chat-settings/chat-lists/model.dart';

class CreateChatList {
  const CreateChatList();
}

class UpdateChatList {
  final ChatList? list;
  const UpdateChatList({this.list});
}

class DeleteChatList {
  final ChatList? list;
  const DeleteChatList({this.list});
}

ThunkAction<AppState> createChatList() {
  return (Store<AppState> store) async {
    store.dispatch(CreateChatList());
  };
}

ThunkAction<AppState> updateChatList(ChatList? list) {
  return (Store<AppState> store) async {
    store.dispatch(UpdateChatList(list: list));
  };
}

ThunkAction<AppState> removeChatList({String? roomId, int? color}) {
  return (Store<AppState> store) async {
    store.dispatch(SetRoomPrimaryColor(
      roomId: roomId,
      color: color,
    ));
  };
}
