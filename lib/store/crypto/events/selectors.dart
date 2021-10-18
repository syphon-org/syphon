import 'package:redux/redux.dart';
import 'package:syphon/store/index.dart';

bool selectHasDecryptableMessages(Store<AppState> store, String roomId) {
  final messages = store.state.eventStore.messages;
  final decrypted = store.state.eventStore.messagesDecrypted;

  final roomMessages = messages[roomId] ?? [];
  final roomDecrypted = decrypted[roomId] ?? [];

  final ids = roomMessages.map((m) => m.id);
  final decryptedIds = roomDecrypted.map((m) => m.id);

  final hasEncrypted =
      ids.firstWhere((id) => !decryptedIds.contains(id), orElse: () => null);

  return hasEncrypted != null;
}
