import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:Tether/domain/index.dart';

import './model.dart';

const HOMESERVER_SEARCH_SERVICE =
    'https://www.hello-matrix.net/public_servers.php?format=json&only_public=true&show_from=Switzerland+%28Hosttech%29';

class SetLoading {
  final bool loading;

  SetLoading({this.loading});
}

class SetUser {
  final User user;

  SetUser({this.user});
}

class SetHomeserver {
  final dynamic homeserver;

  SetHomeserver({this.homeserver});
}

class SetUsername {
  final String username;

  SetUsername({this.username});
}

ThunkAction<AppState> initAuthObserver() {
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(loading: true));

    store.dispatch(SetLoading(loading: false));
  };
}

ThunkAction<AppState> signupUser({username, homeserver, password}) {
  // return (dispatch, state) =>
  return (Store<AppState> store) async {
    // TODO: call out to matrix here
    store.dispatch(SetLoading(loading: true));

    store.dispatch(SetLoading(loading: false));
  };
}

ThunkAction<AppState> setLoading(bool loading) {
  print('User Set Loading');
  return (Store<AppState> store) async {
    print('Async Set Loading $loading');
    store.dispatch(SetLoading(loading: loading));
  };
}

ThunkAction<AppState> setHomeserver({dynamic homeserver}) {
  return (Store<AppState> store) async {
    store.dispatch(SetHomeserver(homeserver: homeserver['hostname']));
  };
}
