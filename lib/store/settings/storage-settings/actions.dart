import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/store/index.dart';

class SetKeyBackupLocation {
  final String location;
  SetKeyBackupLocation({
    required this.location,
  });
}

ThunkAction<AppState> setKeyBackupLocation(String location) {
  return (Store<AppState> store) async {
    store.dispatch(SetKeyBackupLocation(location: location));
  };
}
