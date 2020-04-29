import 'package:Tether/store/index.dart';
import 'package:Tether/store/settings/actions.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

ThunkAction<AppState> updateRoomPrimaryColor({String roomId, int color}) {
  return (Store<AppState> store) async {
    store.dispatch(SetRoomPrimaryColor(
      roomId: roomId,
      color: color,
    ));
  };
}
