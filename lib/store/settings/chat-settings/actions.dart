import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:syphon/store/index.dart';

class SetRoomPrimaryColor {
  final int? color;
  final String? roomId;

  SetRoomPrimaryColor({
    this.color,
    this.roomId,
  });
}

ThunkAction<AppState> updateRoomPrimaryColor({String? roomId, int? color}) {
  return (Store<AppState> store) async {
    store.dispatch(SetRoomPrimaryColor(
      roomId: roomId,
      color: color,
    ));
  };
}
