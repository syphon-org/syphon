import 'package:Tether/domain/index.dart';

import './model.dart';

List<Chat> chats(AppState state) {
  return state.chatStore.chats;
}
