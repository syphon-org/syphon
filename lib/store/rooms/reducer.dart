import './events/model.dart';
import './actions.dart';
import './state.dart';
import './room/model.dart';

RoomStore roomReducer([RoomStore state = const RoomStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetLoading:
      return state.copyWith(loading: action.loading);
    case SetSyncing:
      return state.copyWith(syncing: action.syncing);
    case SetSynced:
      return state.copyWith(
        synced: action.synced,
        syncing: action.syncing,
        lastSince: action.lastSince,
        lastUpdate: action.synced
            ? DateTime.now().millisecondsSinceEpoch
            : state.lastUpdate,
      );
    case SetSending:
      final rooms = Map<String, Room>.from(state.rooms);
      rooms[action.room.id] = rooms[action.room.id].copyWith(
        sending: action.sending,
      );
      return state.copyWith(rooms: rooms);

    case SetRoomObserver:
      return state.copyWith(roomObserver: action.roomObserver);

    case SetRooms:
      final Map<String, Room> rooms = Map.fromIterable(
        action.rooms,
        key: (room) => room.id,
        value: (room) => room,
      );
      return state.copyWith(rooms: rooms);

    case SetRoom:
      final rooms = Map<String, Room>.from(state.rooms);
      rooms[action.room.id] = action.room;
      return state.copyWith(rooms: rooms);

    case UpdateRoom:
      final rooms = Map<String, Room>.from(state.rooms);
      rooms[action.id] = rooms[action.id].copyWith(
        draft: action.draft,
        syncing: action.syncing,
      );
      return state.copyWith(rooms: rooms);

    case RemoveRoom:
      final rooms = Map<String, Room>.from(state.rooms);
      rooms.remove(action.room.id);
      return state.copyWith(rooms: rooms);

    case SetRoomState:
      final rooms = Map<String, Room>.from(state.rooms);
      rooms[action.id] = rooms[action.id].fromStateEvents(
        action.state,
        currentUser: action.currentUser,
        originDEBUG: '[SetRoomState]',
      );
      return state.copyWith(rooms: rooms);

    case SetRoomMessages:
      final rooms = Map<String, Room>.from(state.rooms);
      rooms[action.id] = rooms[action.id].fromMessageEvents(
        action.messageEvents,
        startTime: action.startTime,
        endTime: action.endTime,
      );
      return state.copyWith(rooms: rooms);

    case SaveOutboxMessage:
      final rooms = Map<String, Room>.from(state.rooms);
      final outbox = List<Message>.from(rooms[action.id].outbox);
      if (action.tempId != null) {
        outbox.retainWhere((element) => element.id != action.tempId);
      }
      outbox.add(action.pendingMessage);
      rooms[action.id] = rooms[action.id].copyWith(outbox: outbox);
      return state.copyWith(rooms: rooms);

    case DeleteOutboxMessage:
      final message = action.message;
      final rooms = Map<String, Room>.from(state.rooms);
      final room = rooms[message.roomId];
      final outbox = List<Message>.from(room.outbox);

      outbox.removeWhere((m) => m.id == message.id);
      rooms[message.roomId] = room.copyWith(outbox: outbox);
      return state.copyWith(rooms: rooms);

    case ResetRooms:
      return RoomStore();
    default:
      return state;
  }
}
