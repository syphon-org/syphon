import 'package:flutter/foundation.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/events/ephemeral/m.read/model.dart';
import 'package:syphon/store/events/messages/actions.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/messages/storage.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/settings/models.dart';

class ResetEvents {}

class SetEvents {
  final String? roomId;
  final List<Event>? events;
  SetEvents({this.roomId, this.events});
}

class AddMessagesDecrypted {
  final String roomId;
  final List<Message> messages;
  final List<Message> outbox;

  AddMessagesDecrypted({
    required this.roomId,
    this.messages = const [],
    this.outbox = const [],
  });
}

class AddMessages {
  final String roomId;
  final List<Message> messages;
  final List<Message> outbox;
  final bool clear;

  AddMessages({
    required this.roomId,
    this.messages = const [],
    this.outbox = const [],
    this.clear = false,
  });
}

class SetReceipts {
  final String? roomId;
  final Map<String, ReadReceipt>? receipts;
  SetReceipts({this.roomId, this.receipts});
}

class LoadReceipts {
  final Map<String, Map<String, ReadReceipt>> receiptsMap;
  LoadReceipts({required this.receiptsMap});
}

///
/// Save Outbox Message
///
/// tempId is for messages that have attempted sending but
/// are still in an unknown state remotely
///
class SaveOutboxMessage {
  final String tempId;
  final Message pendingMessage;

  SaveOutboxMessage({
    required this.tempId,
    required this.pendingMessage,
  });
}

class DeleteOutboxMessage {
  final Message message; // room id

  DeleteOutboxMessage({required this.message});
}

class DeleteMessage {
  final Room room;
  final Message message;

  DeleteMessage({required this.room, required this.message});
}

ThunkAction<AppState> addMessages({
  required Room room,
  List<Message> messages = const [],
  List<Message> outbox = const [],
}) =>
    (Store<AppState> store) {
      if (messages.isEmpty && outbox.isEmpty) return;

      return store.dispatch(
        AddMessages(roomId: room.id, messages: messages, outbox: outbox),
      );
    };

///
/// Add Messages Decrypted
///
/// Saves in memory only version of the decrypted message
///
ThunkAction<AppState> addMessagesDecrypted({
  required Room room,
  required List<Message> messages,
  List<Message> outbox = const [],
}) =>
    (Store<AppState> store) {
      if (messages.isEmpty && outbox.isEmpty) return;

      return store.dispatch(
        AddMessagesDecrypted(roomId: room.id, messages: messages, outbox: outbox),
      );
    };

ThunkAction<AppState> setReceipts({
  Room? room,
  Map<String, ReadReceipt>? receipts,
}) =>
    (Store<AppState> store) {
      if (receipts!.isEmpty) return;
      return store.dispatch(SetReceipts(roomId: room!.id, receipts: receipts));
    };

///
/// Load Messages Cached
///
/// Pulls initial messages from storage or paginates through
/// those existing in cold storage depending on requests from client
///
/// Make sure these have been exhausted before calling fetchMessageEvents
///
/// TODO: will need to handle loading all encrypted messages under new
/// sessions in order to decrypt correctly, at least up until the previous
/// session was created
///
ThunkAction<AppState> loadMessagesCached({
  Room? room,
  String? batch,
  int timestamp = 0, // offset
  int limit = LOAD_LIMIT,
}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(UpdateRoom(id: room!.id, syncing: true));

      final messagesStored = await loadMessages(
        storage: Storage.database!,
        roomId: room.id,
        limit: !room.encryptionEnabled ? limit : 0,
        timestamp: timestamp,
        batch: batch,
      );

      // load cold storage messages to state
      if (messagesStored.isNotEmpty) {
        store.dispatch(AddMessages(roomId: room.id, messages: messagesStored));
      }

      return messagesStored;
    } catch (error) {
      printError('[fetchMessageEvents] $error');
    } finally {
      store.dispatch(UpdateRoom(id: room!.id, syncing: false));
    }
  };
}

/// Fetch Message Events
///
/// https://matrix.org/docs/spec/client_server/latest#syncing
/// https://matrix.org/docs/spec/client_server/latest#get-matrix-client-r0-rooms-roomid-messages
///
/// Pulls next message events remote from homeserver
ThunkAction<AppState> fetchMessageEvents({
  Room? room,
  String? to,
  String? from,
  int timestamp = 0,
  int limit = LOAD_LIMIT,
}) {
  return (Store<AppState> store) async {
    try {
      final cached = await store.dispatch(
        loadMessagesCached(room: room, batch: from, limit: limit, timestamp: timestamp),
      ) as List<Message>;

      final oldest = cached.isEmpty;

      if (!oldest) {
        return;
      }

      // mark syncing (to show loading indicators) since it needs to pull remotely
      store.dispatch(UpdateRoom(id: room!.id, syncing: true));

      final messagesJson = await compute(MatrixApi.fetchMessageEventsThreaded, {
        'protocol': store.state.authStore.protocol,
        'homeserver': store.state.authStore.user.homeserver,
        'accessToken': store.state.authStore.user.accessToken,
        'roomId': room.id,
        'limit': limit,
        'from': from ?? room.prevBatch,
        'to': to,
      });

      // The token the pagination ends at. If dir=b this token should be used again to request even earlier events.
      // WARNING: this will be null if there are no more events or batches left to fetch
      final String? end = messagesJson['end'];

      // The token the pagination starts from. If dir=b this will be the token supplied in from.
      final String? start = messagesJson['start'];

      // The messages themselves
      final List<dynamic> messages = messagesJson['chunk'] ?? [];

      // reuse the logic for syncing
      // end will be null if no more batches are available to fetch
      await store.dispatch(syncRooms({
        room.id: {
          'timeline': {
            'events': messages,
            'curr_batch': start,
            'last_batch': oldest ? end ?? from : null,
            'prev_batch': end,
            'limited': end == start || end == null ? false : null,
          }
        },
      }));
    } catch (error) {
      printError('[fetchMessageEvents] error $error');
    } finally {
      store.dispatch(UpdateRoom(id: room!.id, syncing: false));
    }
  };
}

///
/// Fetch State Events
///
/// state events can only be
/// done from full state /sync data
ThunkAction<AppState> fetchStateEvents({Room? room}) {
  return (Store<AppState> store) async {
    try {
      final stateEvents = await MatrixApi.fetchStateEvents(
        protocol: store.state.authStore.protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        roomId: room!.id,
      );

      if (stateEvents.runtimeType != List && stateEvents['errcode'] != null) {
        throw stateEvents['error'];
      }

      await store.dispatch(syncRooms({
        room.id: {
          'state': {
            'events': stateEvents,
          },
        },
      }));
    } catch (error) {
      printError('[fetchStateEvents] $error');
    } finally {
      store.dispatch(UpdateRoom(id: room!.id, syncing: false));
    }
  };
}

ThunkAction<AppState> clearDraft({Room? room}) {
  return (Store<AppState> store) async {
    store.dispatch(UpdateRoom(
      id: room!.id,
      draft: Message(
        roomId: room.id,
        body: null,
      ),
    ));
  };
}

ThunkAction<AppState> saveDraft({
  final body,
  String? type = 'm.text',
  Room? room,
}) {
  return (Store<AppState> store) async {
    store.dispatch(UpdateRoom(
      id: room!.id,
      draft: Message(
        roomId: room.id,
        type: type,
        body: body,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    ));
  };
}

ThunkAction<AppState> selectReply({
  String? roomId,
  Message? message,
}) {
  return (Store<AppState> store) async {
    final room = store.state.roomStore.rooms[roomId!]!;
    store.dispatch(SetRoom(room: room.copyWith(reply: message ?? Null)));
  };
}

///
/// Read Message Marker
///
/// Send Fully Read or just Read receipts bundled into
/// one http call
ThunkAction<AppState> sendReadReceipts({
  Room? room,
  Message? message,
  bool readAll = true,
}) {
  return (Store<AppState> store) async {
    try {
      // Skip if typing indicators are disabled
      if (store.state.settingsStore.readReceipts == ReadReceiptTypes.Off) {
        return printInfo('[sendReadReceipts] read receipts disabled');
      }

      if (store.state.settingsStore.readReceipts == ReadReceiptTypes.Hidden) {
        printInfo('[sendReadReceipts] read receipts hidden');
      }

      final data = await MatrixApi.sendReadReceipts(
        protocol: store.state.authStore.protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room!.id,
        messageId: message!.id,
        readAll: readAll,
        hidden: store.state.settingsStore.readReceipts == ReadReceiptTypes.Hidden,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      printInfo('[sendReadReceipts] sent ${message.id} $data');
    } catch (error) {
      printInfo('[sendReadReceipts] failed $error');
    }
  };
}

///
/// Read Message Marker
///
/// Send Fully Read or just Read receipts bundled into
/// one http call
ThunkAction<AppState> sendTyping({
  String? roomId,
  bool? typing = false,
}) {
  return (Store<AppState> store) async {
    try {
      // Skip if typing indicators are disabled
      if (!store.state.settingsStore.typingIndicatorsEnabled) {
        printInfo('[sendTyping] typing indicators disabled');
        return;
      }

      final data = await MatrixApi.sendTyping(
        protocol: store.state.authStore.protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: roomId,
        userId: store.state.authStore.user.userId,
        typing: typing,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }
    } catch (error) {
      printError('[sendTyping] $error');
    }
  };
}

/// Delete Room Event (For Outbox, Local, and Remote)
ThunkAction<AppState> deleteMessage({required Message message, required Room room}) {
  return (Store<AppState> store) async {
    try {
      if (message.pending || message.failed) {
        return store.dispatch(DeleteOutboxMessage(message: message));
      }

      final currentUser = store.state.authStore.currentUser;

      final canDelete = await isMessageDeletable(
        message: message,
        user: currentUser,
        room: room,
      );

      if (!canDelete) {
        store.dispatch(addInfo(
          message: 'You don\'t have permissions to delete this message.',
          action: 'Dismiss',
        ));
        return;
      }

      final result = await MatrixApi.deleteMessage(
        roomId: room.id,
        eventId: message.id,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
      );

      if (!result) {
        throw 'Failed to delete message, try again soon';
      }

      // deleted messages returned remotely will have empty 'body' fields
      final messageDeleted = message.copyWith(body: '');

      return store.dispatch(DeleteMessage(room: room, message: messageDeleted));
    } catch (error) {
      printError('[deleteMessage] $error');
    }
  };
}
