import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:syphon/store/index.dart';

class ToggleProxy {}

class ToggleProxyAuthentication {}


///
/// Toggle HTTP Proxying
///
ThunkAction<AppState> toggleProxy() {
  return (Store<AppState> store) async {
    store.dispatch(ToggleProxy());
  };
}

ThunkAction<AppState> toggleProxyAuthentication() {
  return (Store<AppState> store) async {
    store.dispatch(ToggleProxyAuthentication());
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

class SetProxyUsername {
  final String username;
  SetProxyUsername({
    required this.username,
  });
}

class SetProxyPassword {
  final String password;
  SetProxyPassword({
    required this.password,
  });
}
