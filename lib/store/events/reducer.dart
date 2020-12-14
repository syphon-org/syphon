// Project imports:
import './actions.dart';
import '../events/model.dart';
import './state.dart';

EventStore eventReducer(
    [EventStore state = const EventStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetMessages:
      final roomId = action.roomId;
      final messages = Map<String, List<Message>>.from(state.messages);
      final messagesOld = Map<String, Message>.fromIterable(
        messages[roomId] ?? [],
        key: (msg) => msg.id,
        value: (msg) => msg,
      );
      final messagesNew = Map<String, Message>.fromIterable(
        action.messages ?? [],
        key: (msg) => msg.id,
        value: (msg) => msg,
      );

      final messagesAll = messagesOld..addAll(messagesNew);

      messages[roomId] = messagesAll.values.toList();

      return state.copyWith(messages: messages);

    case SetState:
      final roomId = action.roomId;
      final states = Map<String, List<Event>>.from(state.states);
      states[roomId] = action.state;
      return state.copyWith(states: states);

    case ResetEvents:
      return EventStore();
    default:
      return state;
  }
}
