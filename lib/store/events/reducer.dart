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
      messages[roomId] = action.messages;
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
