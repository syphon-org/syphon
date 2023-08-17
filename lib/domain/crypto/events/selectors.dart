import 'package:syphon/domain/index.dart';

bool selectHasDecryptableMessages(AppState state, String roomId) {
  final messages = state.eventStore.messages;
  final decrypted = state.eventStore.messagesDecrypted;

  final roomMessages = messages[roomId] ?? [];
  final roomDecrypted = decrypted[roomId] ?? [];

  final ids = roomMessages.map((m) => m.id);
  final decryptedIds = roomDecrypted.map((m) => m.id);

  final hasEncrypted = ids.firstWhere((id) => !decryptedIds.contains(id), orElse: () => null);

  return hasEncrypted != null;
}
