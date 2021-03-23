// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

// Project imports:
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/crypto/events/actions.dart';
import 'package:syphon/store/events/receipts/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/redactions/model.dart';
import 'package:syphon/store/events/storage.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/rooms/room/model.dart';

final protocol = DotEnv().env['PROTOCOL'];

class SetEvents {
  final String roomId;
  final List<Event> events;
  SetEvents({this.roomId, this.events});
}

class SetMessages {
  final String roomId;
  final List<Message> messages;
  SetMessages({this.roomId, this.messages});
}

class SetReactions {
  final String roomId;
  final List<Reaction> reactions;
  SetReactions({this.roomId, this.reactions});
}

class SetReceipts {
  final String roomId;
  final Map<String, ReadReceipt> receipts;
  SetReceipts({this.roomId, this.receipts});
}

class SetRedactions {
  final List<Redaction> redactions;
  SetRedactions({this.redactions});
}

class LoadMessages {
  final Map<String, List<Message>> messagesMap;
  LoadMessages({this.messagesMap});
}

class LoadReactions {
  final Map<String, List<Reaction>> reactionsMap;
  LoadReactions({this.reactionsMap});
}

class LoadReceipts {
  final Map<String, Map<String, ReadReceipt>> receiptsMap;
  LoadReceipts({this.receiptsMap});
}

class LoadRedactions {
  final Map<String, Redaction> redactionsMap;
  LoadRedactions({this.redactionsMap});
}

class ResetEvents {}

ThunkAction<AppState> setMessages({
  Room room,
  List<Message> messages,
  int offset = 0,
  int limit = 20,
}) =>
    (Store<AppState> store) {
      if (messages.isEmpty) return;
      return store.dispatch(SetMessages(roomId: room.id, messages: messages));
    };

ThunkAction<AppState> setReactions({
  List<Reaction> reactions,
}) =>
    (Store<AppState> store) {
      if (reactions.isEmpty) return;
      return store.dispatch(SetReactions(reactions: reactions));
    };

ThunkAction<AppState> setRedactions({
  String roomId,
  List<Redaction> redactions,
}) =>
    (Store<AppState> store) {
      if (redactions.isEmpty) return;
      store.dispatch(SetRedactions(redactions: redactions));
    };

ThunkAction<AppState> setReceipts({
  Room room,
  Map<String, ReadReceipt> receipts,
}) =>
    (Store<AppState> store) {
      if (receipts.isEmpty) return;
      return store.dispatch(SetReceipts(roomId: room.id, receipts: receipts));
    };

/**
 * Load Message Events
 * 
 * Pulls initial messages from storage or paginates through
 * those existing in cold storage depending on requests from client
 * 
 * Make sure these have been exhausted before calling fetchMessageEvents
 * 
 */
ThunkAction<AppState> loadMessagesCached({
  Room room,
  int offset = 0,
  int limit = 20,
}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(UpdateRoom(id: room.id, syncing: true));

      final messagesStored = await loadMessages(
        room.messageIds,
        storage: Storage.main,
        offset: offset, // offset from the most recent eventId found
        limit: !room.encryptionEnabled ? limit : room.messageIds.length,
      );

      // load cold storage messages to state
      store.dispatch(SetMessages(
        roomId: room.id,
        messages: messagesStored,
      ));
    } catch (error) {
      printError('[fetchMessageEvents] $error');
    } finally {
      store.dispatch(UpdateRoom(id: room.id, syncing: false));
    }
  };
}

/**
 * Fetch Message Events
 * 
 * https://matrix.org/docs/spec/client_server/latest#syncing
 * https://matrix.org/docs/spec/client_server/latest#get-matrix-client-r0-rooms-roomid-messages
 * 
 * Pulls next message events remote from homeserver
 */
ThunkAction<AppState> fetchMessageEvents({
  Room room,
  String to,
  String from,
  bool oldest = false, // fetching from the oldest known batch
  bool limited = false, // fetching using the last known limited batch
  int limit = 20,
}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(UpdateRoom(id: room.id, syncing: true));

      final messagesJson = await compute(MatrixApi.fetchMessageEventsMapped, {
        "protocol": protocol,
        "homeserver": store.state.authStore.user.homeserver,
        "accessToken": store.state.authStore.user.accessToken,
        "roomId": room.id,
        "to": to,
        "from": from,
        "limit": limit,
      });

      // The token the pagination ends at. If dir=b this token should be used again to request even earlier events.
      final String end = messagesJson['end'];

      // The token the pagination starts from. If dir=b this will be the token supplied in from.
      final String start = messagesJson['start'];

      // The messages themselves
      final List<dynamic> messages = messagesJson['chunk'] ?? [];

      // reuse the logic for syncing
      await store.dispatch(syncRooms({
        '${room.id}': {
          'timeline': {
            'events': messages,
            'prev_batch': end,
            'limited': limited,
            'oldest': oldest,
          }
        },
      }));
    } catch (error) {
      debugPrint('[fetchMessageEvents] error $error');
    } finally {
      store.dispatch(UpdateRoom(id: room.id, syncing: false));
    }
  };
}

/**
 * Decrypt Events
 * 
 * Reattribute decrypted events to the timeline
 */
ThunkAction<AppState> decryptEvents(Room room, Map<String, dynamic> json) {
  return (Store<AppState> store) async {
    try {
      // First past to decrypt encrypted events
      final List<dynamic> timelineEvents = json['timeline']['events'];

      // map through each event and decrypt if possible
      final decryptTimelineActions = timelineEvents.map((event) async {
        final eventType = event['type'];
        switch (eventType) {
          case EventTypes.encrypted:
            return await store.dispatch(
              decryptMessageEvent(roomId: room.id, event: event),
            );
          default:
            return event;
        }
      });

      // add the decrypted events back to the
      final decryptedTimelineEvents = await Future.wait(
        decryptTimelineActions,
      );

      return decryptedTimelineEvents;
    } catch (error) {
      debugPrint(
        '[decryptEvents] ${room.name ?? 'Unknown Room Name'} ${error.toString()}',
      );
    } finally {
      store.dispatch(UpdateRoom(id: room.id, syncing: false));
    }
  };
}

/**
 *  
 * Fetch State Events
 * 
 * state events can only be 
 * done from full state /sync data
 */
ThunkAction<AppState> fetchStateEvents({Room room}) {
  return (Store<AppState> store) async {
    try {
      final stateEvents = await MatrixApi.fetchStateEvents(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        roomId: room.id,
      );

      if (!(stateEvents is List) && stateEvents['errcode'] != null) {
        throw stateEvents['error'];
      }

      await store.dispatch(syncRooms({
        '${room.id}': {
          'state': {
            'events': stateEvents,
          },
        },
      }));
    } catch (error) {
      debugPrint('[fetchStateEvents] $error');
    } finally {
      store.dispatch(UpdateRoom(id: room.id, syncing: false));
    }
  };
}

ThunkAction<AppState> clearDraft({Room room}) {
  return (Store<AppState> store) async {
    store.dispatch(UpdateRoom(
      id: room.id,
      draft: Message(
        roomId: room.id,
        body: null,
      ),
    ));
  };
}

ThunkAction<AppState> saveDraft({
  final body,
  String type = 'm.text',
  Room room,
}) {
  return (Store<AppState> store) async {
    store.dispatch(UpdateRoom(
      id: room.id,
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
  String roomId,
  Message message,
}) {
  return (Store<AppState> store) async {
    final room = store.state.roomStore.rooms[roomId];
    final reply = message == null ? Message() : message;
    store.dispatch(SetRoom(room: room.copyWith(reply: reply)));
  };
}

///
/// Format Message Reply
///
/// Format a message as a reply to another
/// https://matrix.org/docs/spec/client_server/latest#rich-replies
/// https://github.com/matrix-org/matrix-doc/pull/1767
///
///
ThunkAction<AppState> formatMessageReply(
  Room room,
  Message message,
  Message reply,
) {
  return (Store<AppState> store) async {
    try {
      final body = '''> <${reply.sender}> ${reply.body}\n\n${message.body}''';
      final formattedBody =
          '''<mx-reply><blockquote><a href="https://matrix.to/#/${room.id}/${reply.id}">In reply to</a><a href="https://matrix.to/#/${reply.sender}">${reply.sender}</a><br />${reply.formattedBody ?? reply.body}</blockquote></mx-reply>${message.formattedBody ?? message.body}''';

      return message.copyWith(
        body: body,
        format: "org.matrix.custom.html",
        formattedBody: formattedBody,
        content: {
          "body": body,
          "format": "org.matrix.custom.html",
          "formatted_body": formattedBody,
          // m.relates_to below is not necessary in the unencrypted part of the
          // message according to the spec but Element web and android seem to
          // do it so I'm leaving it here
          "m.relates_to": {
            "m.in_reply_to": {"event_id": "${reply.id}"}
          },
          "msgtype": message.type
        },
      );
    } catch (error) {
      return null;
    }
  };
}

/**
 * 
 * Read Message Marker
 * 
 * Send Fully Read or just Read receipts bundled into 
 * one http call
 */
ThunkAction<AppState> sendReadReceipts({
  Room room,
  Message message,
  bool readAll = true,
}) {
  return (Store<AppState> store) async {
    try {
      // Skip if typing indicators are disabled
      if (!store.state.settingsStore.readReceipts) {
        return debugPrint('[sendReadReceipts] read receipts disabled');
      }

      final data = await MatrixApi.sendReadReceipts(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room.id,
        messageId: message.id,
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
/**
 * 
 * Read Message Marker
 * 
 * Send Fully Read or just Read receipts bundled into 
 * one http call
 */

ThunkAction<AppState> sendTyping({
  String roomId,
  bool typing = false,
}) {
  return (Store<AppState> store) async {
    try {
      // Skip if typing indicators are disabled
      if (!store.state.settingsStore.typingIndicators) {
        debugPrint('[sendTyping] typing indicators disabled');
        return;
      }

      final data = await MatrixApi.sendTyping(
        protocol: protocol,
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

/**
 * Delete Room Event (For Outbox, Local, and Remote)
 */

ThunkAction<AppState> deleteMessage({
  Message message,
}) {
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
  Room room,
  Event event,
}) {
  return (Store<AppState> store) async {
    try {
      await MatrixApi.redactEvent(
        trxId: DateTime.now().millisecond.toString(),
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room.id,
        eventId: event.id,
      );
    } catch (error) {
      debugPrint('[deleteMessage] $error');
    }
  };
}
