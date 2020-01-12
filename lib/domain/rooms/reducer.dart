import './model.dart';
import './actions.dart';

RoomStore roomReducer([RoomStore state = const RoomStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetLoading:
      return state.copyWith(loading: action.loading);
    case SetSyncing:
      return state.copyWith(syncing: action.syncing);
    case SetRoomObserver:
      return state.copyWith(roomObserver: action.chatObserver);
    case SetRooms:
      return state.copyWith(rooms: action.rooms);

    case SetRoom:
      final rooms = List<Room>.from(state.rooms);
      final index = rooms.indexWhere((room) => room.id == action.room.id);

      rooms.replaceRange(index, index + 1, [action.room]);
      return state.copyWith(rooms: rooms);

    case SetRoomState: // TODO: refactor to map
      final rooms = List<Room>.from(state.rooms);
      final index = rooms.indexWhere((room) => room.id == action.id);
      var updated = rooms[index]
          .fromStateEvents(action.state, currentUsername: action.username);

      rooms.replaceRange(index, index + 1, [updated]);
      return state.copyWith(rooms: rooms);

    case SetRoomMessages: // TODO: refactor to map
      final rooms = List<Room>.from(state.rooms);
      final index = rooms.indexWhere((room) => room.id == action.id);
      var updated = rooms[index].fromMessageEvents(action.messagesJson);

      rooms.replaceRange(index, index + 1, [updated]);
      return state.copyWith(rooms: rooms);

    case UpdateRoom: // TODO: refactor to map
      final rooms = List<Room>.from(state.rooms);
      final index = rooms.indexWhere((room) => room.id == action.id);
      final updatedRoom = state.rooms[index].copyWith(
        avatar: action.avatar,
        syncing: action.syncing,
      );

      rooms.replaceRange(index, index + 1, [updatedRoom]);
      return state.copyWith(rooms: rooms);
    default:
      return state;
  }
}
