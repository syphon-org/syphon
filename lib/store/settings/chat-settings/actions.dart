import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';

ThunkAction<AppState> updateRoomPrimaryColor({String? roomId, int? color}) {
  return (Store<AppState> store) async {
    store.dispatch(SetRoomPrimaryColor(
      roomId: roomId,
      color: color,
    ));
  };
}
