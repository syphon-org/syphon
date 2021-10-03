import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/events/ephemeral/m.read/model.dart';
import 'package:syphon/store/events/messages/storage.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/redaction/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/rooms/room/model.dart';

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

  AddMessages({
    required this.roomId,
    this.messages = const [],
    this.outbox = const [],
  });
}

class SetReactions {
  final String? roomId;
  final List<Reaction>? reactions;
  SetReactions({this.roomId, this.reactions});
}

class SetReceipts {
  final String? roomId;
  final Map<String, ReadReceipt>? receipts;
  SetReceipts({this.roomId, this.receipts});
}

class SetRedactions {
  final List<Redaction>? redactions;
  SetRedactions({this.redactions});
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

///
/// Save Outbox Message
///
/// tempId is for messages that have attempted sending but
/// are still in an unknown state remotely
///
class DeleteOutboxMessage {
  final Message message; // room id

  DeleteOutboxMessage({required this.message});
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

ThunkAction<AppState> setReactions({
  List<Reaction> reactions = const [],
}) =>
    (Store<AppState> store) {
      if (reactions.isEmpty) return;
      return store.dispatch(SetReactions(reactions: reactions));
    };

ThunkAction<AppState> setRedactions({
  String? roomId,
  List<Redaction>? redactions,
}) =>
    (Store<AppState> store) {
      if (redactions!.isEmpty) return;
      store.dispatch(SetRedactions(redactions: redactions));
    };

ThunkAction<AppState> setReceipts({
  Room? room,
  Map<String, ReadReceipt>? receipts,
}) =>
    (Store<AppState> store) {
      if (receipts!.isEmpty) return;
      return store.dispatch(SetReceipts(roomId: room!.id, receipts: receipts));
    };

/// Load Message Events
///
/// Pulls initial messages from storage or paginates through
/// those existing in cold storage depending on requests from client
///
/// Make sure these have been exhausted before calling fetchMessageEvents
///
ThunkAction<AppState> loadMessagesCached({
  Room? room,
  int offset = 0,
  int limit = 20,
}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(UpdateRoom(id: room!.id, syncing: true));

      final messagesStored = await loadMessages(
        room.messageIds,
        storage: Storage.database!,
        offset: offset, // offset from the most recent eventId found
        limit: !room.encryptionEnabled ? limit : room.messageIds.length,
      );

      // load cold storage messages to state
      store.dispatch(AddMessages(roomId: room.id, messages: messagesStored));
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
  bool oldest = false,
  int limit = 20,
}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(UpdateRoom(id: room!.id, syncing: true));

      final messagesJson = await compute(MatrixApi.fetchMessageEventsMapped, {
        'protocol': store.state.authStore.protocol,
        'homeserver': store.state.authStore.user.homeserver,
        'accessToken': store.state.authStore.user.accessToken,
        'roomId': room.id,
        'to': to,
        'from': from,
        'limit': limit,
      });

      // The token the pagination ends at. If dir=b this token should be used again to request even earlier events.
      final String? end = messagesJson['end'];

      // The token the pagination starts from. If dir=b this will be the token supplied in from.
      final String? start = messagesJson['start'];

      // The messages themselves
      final List<dynamic> messages = messagesJson['chunk'] ?? [];

      // reuse the logic for syncing
      await store.dispatch(
        syncRooms({
          room.id: {
            'timeline': {
              'events': messages,
              'last_hash': oldest ? end : null,
              'prev_batch': end,
              'limited': end == start ? false : null,
            }
          },
        }),
      );
    } catch (error) {
      debugPrint('[fetchMessageEvents] error $error');
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
      if (!store.state.settingsStore.readReceiptsEnabled) {
        return debugPrint('[sendReadReceipts] read receipts disabled');
      }

      final data = await MatrixApi.sendReadReceipts(
        protocol: store.state.authStore.protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room!.id,
        messageId: message!.id,
        readAll: readAll,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      debugPrint('[sendReadReceipts] sent ${message.id} $data');
    } catch (error) {
      debugPrint('[sendReadReceipts] failed $error');
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
        debugPrint('[sendTyping] typing indicators disabled');
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
      debugPrint('[sendTyping] $error');
    }
  };
}

/// Delete Room Event (For Outbox, Local, and Remote)
ThunkAction<AppState> deleteMessage({required Message message}) {
  return (Store<AppState> store) async {
    try {
      if (message.pending || message.failed) {
        return store.dispatch(DeleteOutboxMessage(message: message));
      }
    } catch (error) {
      debugPrint('[deleteMessage] $error');
    }
  };
}

///
/// Redact Event
///
/// Only use when you're sure no temporary events
/// can be removed first (like failed or pending sends)
///
ThunkAction<AppState> redactEvent({
  Room? room,
  Event? event,
}) {
  return (Store<AppState> store) async {
    try {
      await MatrixApi.redactEvent(
        trxId: DateTime.now().millisecond.toString(),
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room!.id,
        eventId: event!.id,
      );
    } catch (error) {
      debugPrint('[deleteMessage] $error');
    }
  };
}
