import 'package:Tether/domain/index.dart';

import './model.dart';

List<Room> rooms(AppState state) {
  return state.roomStore.rooms;
}

Room room({AppState appState, String id}) {
  return appState.roomStore.rooms.firstWhere((r) => r.id == id);
}
