import './actions.dart';
import './model.dart';
import './room/model.dart';

RoomStore roomReducer([RoomStore state = const RoomStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetLoading:
      return state.copyWith(loading: action.loading);
    case SetSyncing:
      return state.copyWith(syncing: action.syncing);
    case SetRoomObserver:
      return state.copyWith(roomObserver: action.chatObserver);

    case SetRoom:
      final rooms = Map<String, Room>.from(state.rooms);
      rooms[action.room.id] = action.room;
      return state.copyWith(rooms: rooms);

    case SetRooms:
      final Map<String, Room> rooms = Map.fromIterable(
        action.rooms,
        key: (room) => room.id,
        value: (room) => room,
      );
      return state.copyWith(rooms: rooms);

    case SetRoomState:
      final rooms = Map<String, Room>.from(state.rooms);
      rooms[action.id] = rooms[action.id].fromStateEvents(
        action.state,
        currentUsername: action.username,
      );
      return state.copyWith(rooms: rooms);

    case SetRoomMessages:
      final rooms = Map<String, Room>.from(state.rooms);
      rooms[action.id] = rooms[action.id].fromMessageEvents(
        action.messagesJson,
      );
      return state.copyWith(rooms: rooms);

    case UpdateRoom:
      final rooms = Map<String, Room>.from(state.rooms);
      rooms[action.id] = rooms[action.id].copyWith(
        avatar: action.avatar,
        syncing: action.syncing,
      );
      return state.copyWith(rooms: rooms);
    default:
      return state;
  }
}
