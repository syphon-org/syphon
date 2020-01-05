import 'package:Tether/domain/index.dart';

import './model.dart';

List<Room> rooms(AppState state) {
  return state.roomStore.rooms;
}
