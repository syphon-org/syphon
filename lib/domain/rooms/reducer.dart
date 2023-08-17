import './actions.dart';
import './room/model.dart';
import './state.dart';

RoomStore roomReducer([RoomStore state = const RoomStore(), dynamic actionAny]) {
  switch (actionAny.runtimeType) {
    case SetLoading:
      return state.copyWith(loading: actionAny.loading);

    case SetRooms:
      final Map<String, Room> rooms = Map.fromIterable(
        actionAny.rooms,
        key: (room) => room.id,
        value: (room) => room,
      );
      return state.copyWith(rooms: rooms);

    case SetRoom:
      final action = actionAny as SetRoom;
      final rooms = Map<String, Room>.from(state.rooms);
      rooms[action.room.id] = action.room;
      return state.copyWith(rooms: rooms);

    case UpdateRoom:
      final rooms = Map<String, Room>.from(state.rooms);

      if (rooms[actionAny.id] == null) {
        return state;
      }

      rooms[actionAny.id] = rooms[actionAny.id]!.copyWith(
        draft: actionAny.draft,
        reply: actionAny.reply,
        sending: actionAny.sending,
        syncing: actionAny.syncing,
        lastRead: actionAny.lastRead,
      );

      return state.copyWith(rooms: rooms);

    case RemoveRoom:
      final rooms = Map<String, Room>.from(state.rooms);
      rooms.remove(actionAny.roomId);
      return state.copyWith(rooms: rooms);

    case AddArchive:
      final rooms = Map<String, Room>.from(state.rooms);
      final room = rooms[actionAny.roomId]!;

      rooms[actionAny.roomId] = room.copyWith(hidden: true);

      return state.copyWith(rooms: rooms);
    case ResetRooms:
      return const RoomStore();
    default:
      return state;
  }
}
