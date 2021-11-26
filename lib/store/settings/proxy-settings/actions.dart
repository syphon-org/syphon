import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:syphon/store/index.dart';

class ToggleProxy {}



///
/// Toggle HTTP Proxying
///
ThunkAction<AppState> toggleProxy() {
  return (Store<AppState> store) async {
    store.dispatch(ToggleProxy());
  };
}

class SetProxyHost {
  final String host;
  SetProxyHost({
    required this.host,
  });
}

class SetProxyPort {
  final String port;
  SetProxyPort({
    required this.port,
  });
}
