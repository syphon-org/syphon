import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/events/reactions/actions.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/redaction/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';

class SaveRedactions {
  final List<Redaction>? redactions;
  SaveRedactions({this.redactions});
}

class LoadRedactions {
  final Map<String, Redaction> redactionsMap;
  LoadRedactions({required this.redactionsMap});
}

ThunkAction<AppState> setRedactions({
  String? roomId,
  List<Redaction>? redactions,
}) =>
    (Store<AppState> store) {
      if (redactions!.isEmpty) return;
      store.dispatch(SaveRedactions(redactions: redactions));
    };

///
/// Send Redaction (Server Side / Remotely)
///
/// Only use when you're sure no temporary events
/// can be removed first (like failed or pending sends)
///
ThunkAction<AppState> sendRedaction({Room? room, Event? event}) {
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
      printError('[deleteMessage] $error');
    }
  };
}

///
/// Redact Events
///
/// Redact messages locally throughout all
/// storage layers
///
ThunkAction<AppState> redactEvents({required Room room, List<Redaction> redactions = const []}) {
  return (Store<AppState> store) async {
    try {
      if (redactions.isEmpty) return;

      final messagesCached = store.state.eventStore.messages[room.id] ?? [];
      final reactionsCached = store.state.eventStore.reactions[room.id] ?? [];

      // create a map of messages for O(1) when replacing O(N)
      final messagesMap = Map<String, Message>.fromIterable(
        messagesCached,
        key: (message) => message.id,
        value: (message) => message,
      );

      // create a map of messages for O(1) when replacing O(N)
      final reactionsMap = Map<String, Reaction>.fromIterable(
        reactionsCached,
        key: (message) => message.id,
        value: (message) => message,
      );

      final messages = <Message>[];
      final reactions = <Reaction>[];

      for (final redaction in redactions) {
        if (messagesMap.containsKey(redaction.redactId)) {
          messages.add(messagesMap[redaction.redactId]!.copyWith(body: null));
        }
        if (reactionsMap.containsKey(redaction.redactId)) {
          reactions.add(reactionsMap[redaction.redactId]!.copyWith(body: null));
        }
      }

      // add messages back to cache having been redacted
      store.dispatch(addMessages(room: room, messages: messages));
      store.dispatch(addReactions(reactions: reactions));

      // save redactions to cold storage
      store.dispatch(SaveRedactions(redactions: redactions));
    } catch (error) {
      printError('[deleteMessage] $error');
    }
  };
}
