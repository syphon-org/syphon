import 'package:syphon/domain/events/messages/model.dart';
import 'package:syphon/domain/events/reactions/actions.dart';
import 'package:syphon/domain/events/reactions/model.dart';
import 'package:syphon/domain/events/receipts/actions.dart';
import 'package:syphon/domain/events/receipts/model.dart';
import 'package:syphon/domain/events/redaction/actions.dart';
import 'package:syphon/domain/events/redaction/model.dart';

import './actions.dart';
import './state.dart';

EventStore eventReducer([EventStore state = const EventStore(), dynamic actionAny]) {
  switch (actionAny.runtimeType) {
    case AddReactions:
      final action = actionAny as AddReactions;
      final reactionsUpdated = Map<String, List<Reaction>>.from(
        state.reactions,
      );

      for (final Reaction reaction in action.reactions ?? []) {
        final reactionEventId = reaction.relEventId;
        final hasReactions = reactionsUpdated.containsKey(reactionEventId);

        if (hasReactions) {
          final reactions = reactionsUpdated[reactionEventId]!;
          final reactionIndex = reactions.indexWhere((value) => value.id == reaction.id);

          if (reactionIndex == -1) {
            reactionsUpdated[reactionEventId!] = [...reactions, reaction];
          } else {
            reactionsUpdated[reactionEventId!] = [...reactions.where((r) => r.id != reaction.id), reaction];
          }
        } else if (reactionEventId != null) {
          reactionsUpdated[reactionEventId] = [reaction];
        }
      }

      return state.copyWith(reactions: reactionsUpdated);

    // set the messages map to exactly what's passed in
    // helps with message revisions after lazy loads
    case SetMessages:
      final action = actionAny as SetMessages;

      final messagesAll = action.all;
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
      final action = actionAny as SetMessagesDecrypted;

      final messagesAll = action.all;
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
      final action = actionAny as AddMessages;
      if (action.messages.isEmpty) {
        return state;
      }

      final roomId = action.roomId;

      // convert to map to merge old and new messages based on ids
      // ignore previous messages and only save the newest to local state if "clear"ing
      final messagesOld = action.clear
          ? <String, Message>{}
          : Map<String, Message>.fromIterable(
              state.messages[roomId] ?? [],
              key: (msg) => msg.id,
              value: (msg) => msg,
            );

      final messagesNew = Map<String, Message>.fromIterable(
        actionAny.messages,
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
      final action = actionAny as AddMessagesDecrypted;
      final roomId = action.roomId;

      if (action.messages.isEmpty) {
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
        actionAny.messages,
        key: (msg) => msg.id,
        value: (msg) => msg,
      );

      // prioritize new message data though over the old (invalidates using Set)
      final messagesAll = messagesOld..addAll(messagesNew);
      messages[roomId] = messagesAll.values.toList();

      // otherwise, save messages
      return state.copyWith(messagesDecrypted: messages);
    case SaveOutboxMessage:
      final tempId = (actionAny as SaveOutboxMessage).tempId;
      final message = actionAny.pendingMessage;
      final roomId = message.roomId!;

      final outbox = Map<String, Message>.from(state.outbox[roomId] ?? {});

      outbox.addAll({tempId: message});

      final outboxNew = Map<String, Map<String, Message>>.from(state.outbox);

      outboxNew[roomId] = outbox;

      return state.copyWith(outbox: outboxNew);

    case DeleteOutboxMessage:
      final message = (actionAny as DeleteOutboxMessage).message;
      final roomId = message.roomId!;

      final outbox = Map<String, Message>.from(state.outbox[roomId] ?? {});

      outbox.removeWhere((tempId, outmessage) => message.id == outmessage.id);

      final outboxNew = Map<String, Map<String, Message>>.from(state.outbox);

      outboxNew[roomId] = outbox;

      return state.copyWith(outbox: outboxNew);

    case DeleteMessage:
      return state;

    case SaveRedactions:
      final action = actionAny as SaveRedactions;
      if (action.redactions == null || action.redactions!.isEmpty) {
        return state;
      }

      final redactions = Map<String, Redaction>.from(state.redactions);

      final redactionsNew = Map<String, Redaction>.fromIterable(
        actionAny.redactions ?? [],
        key: (redaction) => redaction.redactId,
        value: (redaction) => redaction,
      );

      return state.copyWith(
        redactions: redactions..addAll(redactionsNew),
      );

    case SetReceipts:
      if (actionAny.receipts.isEmpty) {
        return state;
      }

      final roomId = actionAny.roomId;
      final receiptsUpdated = Map<String, Map<String, Receipt>>.from(
        state.receipts,
      );
      final receiptsNew = Map<String, Receipt>.from(
        actionAny.receipts,
      );

      if (receiptsUpdated.containsKey(roomId)) {
        receiptsUpdated[roomId]!.addAll(receiptsNew);
      }

      return state.copyWith(receipts: receiptsUpdated);
    case LoadReactions:
      return state.copyWith(reactions: actionAny.reactionsMap);
    case LoadReceipts:
      return state.copyWith(receipts: actionAny.receiptsMap);
    case ResetEvents:
      return const EventStore();
    default:
      return state;
  }
}
