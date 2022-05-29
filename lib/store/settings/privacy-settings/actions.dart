import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/store/index.dart';

class SetKeyBackupInterval {
  final Duration duration;

  SetKeyBackupInterval({
    required this.duration,
  });
}

ThunkAction<AppState> setKeyBackupInterval(Duration duration) {
  return (Store<AppState> store) async {
    store.dispatch(SetKeyBackupInterval(duration: duration));
  };
}
