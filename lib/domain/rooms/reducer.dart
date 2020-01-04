import './model.dart';
import './actions.dart';

RoomStore chatReducer([RoomStore state = const RoomStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetLoading:
      return state.copyWith(loading: action.loading);
    case SetSyncing:
      return state.copyWith(syncing: action.syncing);
    case SetRoomObserver:
      return state.copyWith(roomObserver: action.chatObserver);
    case SetRooms:
      return state.copyWith(rooms: action.rooms);
    case AddRoom:
      List<Room> rooms = List<Room>.from(state.rooms);
      rooms.add(action.room);
      return state.copyWith(rooms: rooms);
    default:
      return state;
  }
}
