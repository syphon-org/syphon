import 'dart:async';

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
  final bool loading;
  final bool syncing;
  final Timer chatObserver;
  final List<Chat> chats;

  const ChatStore({
    this.syncing = false,
    this.loading = false,
    this.chatObserver,
    this.chats = const [],
  });

  ChatStore copyWith({
    loading,
    syncing,
    chats,
    chatObserver,
  }) {
    return ChatStore(
      loading: loading ?? this.loading,
      syncing: syncing ?? this.syncing,
      chatObserver: chatObserver ?? this.chatObserver,
      chats: chats ?? this.chats,
    );
  }

  @override
  int get hashCode =>
      loading.hashCode ^
      syncing.hashCode ^
      chatObserver.hashCode ^
      chats.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatStore &&
          runtimeType == other.runtimeType &&
          loading == other.loading &&
          syncing == other.syncing &&
          chatObserver == other.chatObserver &&
          chats == other.chats;

  @override
  String toString() {
    return '{loading: $loading, syncing: $syncing, chatObserver: $chatObserver, chats: $chats}';
  }
}
