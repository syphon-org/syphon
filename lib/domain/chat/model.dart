class Message {
  final int senderId;
  final int receiverId;
  final String body;
  final DateTime timestamp;

  const Message({
    this.senderId,
    this.receiverId,
    this.body,
    this.timestamp,
  });

  @override
  int get hashCode =>
      senderId.hashCode ^
      receiverId.hashCode ^
      body.hashCode ^
      timestamp.hashCode;
}

class Chat {
  final String chatId;
  final String title;
  final List<Message> messages;
  final bool syncing;

  const Chat({
    this.chatId,
    this.title,
    this.messages,
    this.syncing = false,
  });
}

class ChatStore {
  final Map chats;
  final bool counter;
  final bool initing;
  final bool loading;

  const ChatStore({
    this.chats,
    this.counter,
    this.initing,
    this.loading,
  });
}
