// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

// Project imports:
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/rooms/room/model.dart';

ThunkAction<AppState> toggleReaction({
  Room? room,
  Message? message,
  String? emoji,
}) {
  return (Store<AppState> store) async {
    final user = store.state.authStore.user;

    final reaction = message!.reactions.firstWhereOrNull(
        (reaction) => reaction.sender == user.userId && reaction.body == emoji);

    if (reaction == null) {
      store.dispatch(sendReaction(message: message, room: room, emoji: emoji));
    } else {
      store.dispatch(redactEvent(event: reaction, room: room));
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
      debugPrint('[sendReaction] $error');
      return false;
    } finally {
      store.dispatch(UpdateRoom(id: room.id, sending: false));
    }
  };
}
