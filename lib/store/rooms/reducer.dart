import './actions.dart';
import './room/model.dart';
import './state.dart';

RoomStore roomReducer([RoomStore state = const RoomStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetLoading:
      return state.copyWith(loading: action.loading);

    case SetRooms:
      final Map<String, Room> rooms = Map.fromIterable(
        action.rooms,
        key: (room) => room.id,
        value: (room) => room,
      );
      return state.copyWith(rooms: rooms);

    case SetRoom:
      final _action = action as SetRoom;
      final rooms = Map<String, Room>.from(state.rooms);
      rooms[_action.room.id] = _action.room;
      return state.copyWith(rooms: rooms);

    case UpdateRoom:
      final rooms = Map<String, Room>.from(state.rooms);

      if (rooms[action.id] == null) {
        return state;
      }

      rooms[action.id] = rooms[action.id]!.copyWith(
        draft: action.draft,
        reply: action.reply,
        sending: action.sending,
        syncing: action.syncing,
        lastRead: action.lastRead,
      );

      return state.copyWith(rooms: rooms);

    case RemoveRoom:
      final rooms = Map<String, Room>.from(state.rooms);
      rooms.remove(action.roomId);
      return state.copyWith(rooms: rooms);

    case AddArchive:
      final rooms = Map<String, Room>.from(state.rooms);
      final room = rooms[action.roomId]!;

      rooms[action.roomId] = room.copyWith(hidden: true);

      return state.copyWith(rooms: rooms);
    case ResetRooms:
      return RoomStore();
    default:
      return state;
  }
}
