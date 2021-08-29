import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/index.dart';
import './room/model.dart';

Room selectRoom({required AppState state, String? id}) {
  return state.roomStore.rooms[id] ?? Room(id: id ?? '');
}

List<Room> filterBlockedRooms(List<Room> rooms, List<String> blocked) {
  final List<Room> roomList = rooms;

  return roomList
    ..removeWhere((room) =>
        room.userIds.length == 2 &&
        room.userIds.any(
          (userId) => blocked.contains(userId),
        ))
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
