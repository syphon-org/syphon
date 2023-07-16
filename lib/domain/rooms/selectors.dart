import 'package:syphon/domain/events/messages/model.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/user/model.dart';
import './room/model.dart';

Room selectRoom({required AppState state, String? id}) {
  return state.roomStore.rooms[id] ?? Room(id: id ?? '');
}

String selectDirectChatIdExisting({required AppState state, User? user}) {
  if (user == null) return '';

  for (final room in state.roomStore.roomList) {
    if (room.direct && room.userIds.contains(user.userId)) {
      return room.id;
    }
  }

  return '';
}

List<Room> filterBlockedRooms(List<Room> rooms, List<String> blocked) {
  final List<Room> roomList = rooms;

  return roomList
    ..removeWhere(
      (room) =>
          room.userIds.length == 2 &&
          room.userIds.any(
            (userId) => blocked.contains(userId),
          ),
    )
    ..toList();
}

List<Room> filterSearches(List<Room> rooms, List<Message> searchMessages) {
  final List<Room> roomList = rooms;

  if (searchMessages.isEmpty) {
    return rooms;
  }

  final roomIds = Map<String, String>.fromIterable(
    searchMessages,
    key: (msg) => msg.roomId ?? msg.id,
    value: (msg) => msg.id,
  );

  return roomList.where((room) => roomIds.containsKey(room.id)).toList();
}

List<Room> sortPrioritizedRooms(List<Room> rooms) {
  // sort descending
  rooms.sort((a, b) {
    // Prioritze draft rooms
    if (a.drafting && !b.drafting) {
      return -1;
    }
    if (!a.drafting && b.drafting) {
      return 1;
    }
    if (a.invite && !b.invite) {
      return -1;
    }
    if (!a.invite && b.invite) {
      return 1;
    }
    // Prioritze if a direct chat
    if (a.direct && !b.direct) {
      return -1;
    }
    if (!a.direct && b.direct) {
      return 1;
    }
    // Otherwise, use timestamp
    if (a.lastUpdate > b.lastUpdate) {
      return -1;
    }
    if (a.lastUpdate < b.lastUpdate) {
      return 1;
    }

    return 0;
  });

  return rooms;
}

List<Room> availableRooms(List<Room> rooms) {
  return List.from(rooms.where((room) => !room.hidden));
}

List<Room> selectHomeChats(AppState state) {
  return availableRooms(
    sortPrioritizedRooms(
      filterSearches(
        filterBlockedRooms(
          state.roomStore.roomList,
          state.userStore.blocked,
        ),
        state.searchStore.searchMessages,
      ),
    ),
  );
}
