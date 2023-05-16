import 'package:collection/collection.dart' show IterableExtension;
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/domain/events/messages/model.dart';
import 'package:syphon/domain/events/reactions/model.dart';
import 'package:syphon/domain/events/redaction/actions.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/rooms/actions.dart';
import 'package:syphon/domain/rooms/room/model.dart';

class AddReactions {
  final String? roomId;
  final List<Reaction>? reactions;
  AddReactions({this.roomId, this.reactions});
}

class LoadReactions {
  final Map<String, List<Reaction>> reactionsMap;
  LoadReactions({required this.reactionsMap});
}

ThunkAction<AppState> addReactions({
  List<Reaction> reactions = const [],
}) =>
    (Store<AppState> store) {
      if (reactions.isEmpty) return;
      return store.dispatch(AddReactions(reactions: reactions));
    };

ThunkAction<AppState> toggleReaction({
  Room? room,
  Message? message,
  String? emoji,
}) {
  return (Store<AppState> store) async {
    final user = store.state.authStore.user;

    final reaction = message!.reactions
        .firstWhereOrNull((reaction) => reaction.sender == user.userId && reaction.body == emoji);

    if (reaction == null) {
      store.dispatch(sendReaction(message: message, room: room, emoji: emoji));
    } else {
      store.dispatch(sendRedaction(event: reaction, room: room));
    }
  };
}

///
/// Send Reaction
///
ThunkAction<AppState> sendReaction({
  Room? room,
  Message? message,
  String? emoji,
}) {
  return (Store<AppState> store) async {
    store.dispatch(UpdateRoom(id: room!.id, sending: true));
    try {
      await MatrixApi.sendReaction(
        trxId: DateTime.now().millisecond.toString(),
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room.id,
        messageId: message!.id,
        reaction: emoji,
      );

      return true;
    } catch (error) {
      log.error('[sendReaction] $error');
      return false;
    } finally {
      store.dispatch(UpdateRoom(id: room.id, sending: false));
    }
  };
}
