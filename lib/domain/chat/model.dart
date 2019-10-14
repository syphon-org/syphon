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
    this.title = 'New Chat',
    this.messages = const [],
    this.syncing = false,
  });
}

class ChatStore {
  final int counter;
  final bool initing;
  final bool loading;
  final List<Chat> chats;

  const ChatStore({
    this.chats = const [],
    this.initing = true,
    this.loading = false,
    this.counter = 0,
  });

  @override
  int get hashCode =>
      chats.hashCode ^ initing.hashCode ^ counter.hashCode ^ loading.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatStore &&
          runtimeType == other.runtimeType &&
          chats == other.chats &&
          initing == other.initing &&
          loading == other.loading &&
          counter == other.counter;

  @override
  String toString() {
    return 'ChatStore{chats: $chats, initing: $initing, loading: $loading, counter: $counter}';
  }
}
