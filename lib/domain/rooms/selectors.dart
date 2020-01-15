import 'package:Tether/domain/index.dart';

import './model.dart';

List<Room> rooms(AppState state) {
  return state.roomStore.rooms;
}

Room room({AppState state, String id}) {
  return state.roomStore.rooms.firstWhere((room) => room.id == id);
}

List<Room> sortRoomsByPriority(AppState state) {
  final sortedList = List<Room>.from(state.roomStore.rooms);

  sortedList.sort((a, b) {
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

  return sortedList;
}
