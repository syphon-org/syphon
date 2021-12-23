import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/reactions/actions.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/receipts/actions.dart';
import 'package:syphon/store/events/receipts/model.dart';
import 'package:syphon/store/events/redaction/actions.dart';
import 'package:syphon/store/events/redaction/model.dart';

import './actions.dart';
import './state.dart';

EventStore eventReducer([EventStore state = const EventStore(), dynamic action]) {
  switch (action.runtimeType) {
    case AddReactions:
      final _action = action as AddReactions;
      final reactionsUpdated = Map<String, List<Reaction>>.from(
        state.reactions,
      );

      for (final Reaction reaction in _action.reactions ?? []) {
        final reactionEventId = reaction.relEventId;
        final hasReactions = reactionsUpdated.containsKey(reactionEventId);

        if (hasReactions) {
          final reactions = reactionsUpdated[reactionEventId]!;
          final reactionIndex = reactions.indexWhere((value) => value.id == reaction.id);

          if (reactionIndex == -1) {
            reactionsUpdated[reactionEventId!] = [...reactions, reaction];
          } else {
            reactionsUpdated[reactionEventId!] = [
              ...reactions.where((r) => r.id != reaction.id).toList(),
              reaction
            ];
          }
        } else if (reactionEventId != null) {
          reactionsUpdated[reactionEventId] = [reaction];
        }
      }

      return state.copyWith(reactions: reactionsUpdated);

    // set the messages map to exactly what's passed in
    // helps with message revisions after lazy loads
    case SetMessages:
      final _action = action as SetMessages;

      final messagesAll = _action.all;
      final existingAll = state.messages;

      final combinedAll = Map<String, List<Message>>.from(existingAll);

      messagesAll.forEach((roomId, messages) {
        // convert to map to merge old and new messages based on ids
        // ignore previous messages and only save the newest to local state if "clear"ing
        final messagesOld = Map<String, Message>.fromIterable(
          state.messages[roomId] ?? [],
          key: (msg) => msg.id,
          value: (msg) => msg,
        );

        final messagesNew = Map<String, Message>.fromIterable(
          messages,
          key: (msg) => msg.id,
          value: (msg) => msg,
        );

        // prioritize new message data though over the old (invalidates using Map overwrite)
        final combinedNew = messagesOld..addAll(messagesNew);

        combinedAll[roomId] = combinedNew.values.toList();
      });

      return state.copyWith(messages: combinedAll);

    // set the decrypted map to exactly what's passed in
    // helps with message revisions after lazy loads
    case SetMessagesDecrypted:
      final _action = action as SetMessagesDecrypted;

      final messagesAll = _action.all;
      final existingAll = state.messagesDecrypted;

      final combinedAll = Map<String, List<Message>>.from(existingAll);

      messagesAll.forEach((roomId, messages) {
        // convert to map to merge old and new messages based on ids
        // ignore previous messages and only save the newest to local state if "clear"ing
        final messagesOld = Map<String, Message>.fromIterable(
          state.messages[roomId] ?? [],
          key: (msg) => msg.id,
          value: (msg) => msg,
        );

        final messagesNew = Map<String, Message>.fromIterable(
          messages,
          key: (msg) => msg.id,
          value: (msg) => msg,
        );

        // prioritize new message data though over the old (invalidates using Map overwrite)
        final combinedNew = messagesOld..addAll(messagesNew);

        combinedAll[roomId] = combinedNew.values.toList();
      });

      return state.copyWith(messagesDecrypted: combinedAll);
    case AddMessages:
      final _action = action as AddMessages;
      if (_action.messages.isEmpty) {
        return state;
      }

      final roomId = _action.roomId;

      // convert to map to merge old and new messages based on ids
      // ignore previous messages and only save the newest to local state if "clear"ing
      final messagesOld = _action.clear
          ? <String, Message>{}
          : Map<String, Message>.fromIterable(
              state.messages[roomId] ?? [],
              key: (msg) => msg.id,
              value: (msg) => msg,
            );

      final messagesNew = Map<String, Message>.fromIterable(
        action.messages,
        key: (msg) => msg.id,
        value: (msg) => msg,
      );

      // prioritize new message data though over the old (invalidates using Map overwrite)
      final messagesAll = messagesOld..addAll(messagesNew);

      // TODO: check if "messages" can be mutateable here
      final messages = Map<String, List<Message>>.from(state.messages);

      // update values in the mutateable map for only the room involved
      messages[roomId] = messagesAll.values.toList();

      // remove locally saved outbox messages if they've now been received from a server
      if (state.outbox.containsKey(roomId) && state.outbox[roomId]!.isNotEmpty) {
        final outbox = Map<String, Message>.from(state.outbox[roomId] ?? {});

        // removed based on eventId, not tempId
        outbox.removeWhere(
          (tempId, outmessage) => messagesAll.containsKey(outmessage.id),
        );

        final outboxNew = Map<String, Map<String, Message>>.from(state.outbox);

        outboxNew[roomId] = outbox;

        return state.copyWith(messages: messages, outbox: outboxNew);
      }

      // otherwise, save messages
      return state.copyWith(messages: messages);

    case AddMessagesDecrypted:
      final _action = action as AddMessagesDecrypted;
      final roomId = _action.roomId;

      if (_action.messages.isEmpty) {
        return state;
      }

      final messages = Map<String, List<Message>>.from(
        state.messagesDecrypted,
      );

      // convert to map to merge old and new messages based on ids
      final messagesOld = Map<String, Message>.fromIterable(
        messages[roomId] ?? [],
        key: (msg) => msg.id,
        value: (msg) => msg,
      );

      final messagesNew = Map<String, Message>.fromIterable(
        action.messages,
        key: (msg) => msg.id,
        value: (msg) => msg,
      );

      // prioritize new message data though over the old (invalidates using Set)
      final messagesAll = messagesOld..addAll(messagesNew);
      messages[roomId] = messagesAll.values.toList();

      // otherwise, save messages
      return state.copyWith(messagesDecrypted: messages);
    case SaveOutboxMessage:
      final tempId = (action as SaveOutboxMessage).tempId;
      final message = action.pendingMessage;
      final roomId = message.roomId!;

      final outbox = Map<String, Message>.from(state.outbox[roomId] ?? {});

      outbox.addAll({tempId: message});

      final outboxNew = Map<String, Map<String, Message>>.from(state.outbox);

      outboxNew[roomId] = outbox;

      return state.copyWith(outbox: outboxNew);

    case DeleteOutboxMessage:
      final message = (action as DeleteOutboxMessage).message;
      final roomId = message.roomId!;

      final outbox = Map<String, Message>.from(state.outbox[roomId] ?? {});

      outbox.removeWhere((tempId, outmessage) => message.id == outmessage.id);

      final outboxNew = Map<String, Map<String, Message>>.from(state.outbox);

      outboxNew[roomId] = outbox;

      return state.copyWith(outbox: outboxNew);

    case DeleteMessage:
      return state;

    case SaveRedactions:
      final _action = action as SaveRedactions;
      if (_action.redactions == null || _action.redactions!.isEmpty) {
        return state;
      }

      final redactions = Map<String, Redaction>.from(state.redactions);

      final redactionsNew = Map<String, Redaction>.fromIterable(
        action.redactions ?? [],
        key: (redaction) => redaction.redactId,
        value: (redaction) => redaction,
      );

      return state.copyWith(
        redactions: redactions..addAll(redactionsNew),
      );

    case SetReceipts:
      if (action.receipts.isEmpty) {
        return state;
      }

      final roomId = action.roomId;
      final receiptsUpdated = Map<String, Map<String, Receipt>>.from(
        state.receipts,
      );
      final receiptsNew = Map<String, Receipt>.from(
        action.receipts,
      );

      if (receiptsUpdated.containsKey(roomId)) {
        receiptsUpdated[roomId]!.addAll(receiptsNew);
      }

      return state.copyWith(receipts: receiptsUpdated);
    case LoadReactions:
      return state.copyWith(reactions: action.reactionsMap);
    case LoadReceipts:
      return state.copyWith(receipts: action.receiptsMap);
    case ResetEvents:
      return EventStore();
    default:
      return state;
  }
}
