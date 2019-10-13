import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:Tether/domain/index.dart';

import './model.dart';

class SetLoading {
  final bool loading;

  SetLoading(this.loading);
}

class SetUser {
  final User user;

  SetUser(this.user);
}

ThunkAction<AppState> initAuthenticationObserver() {
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(true));

    store.dispatch(SetLoading(false));
  };
}

ThunkAction<AppState> signupUser({username, domain, password}) {
  // return (dispatch, state) =>
  return (Store<AppState> store) async {
    // TODO: call out to matrix here
    store.dispatch(SetLoading(false));
  };
}

ThunkAction<AppState> setLoading(bool loading) {
  print('User Set Loading');
  return (Store<AppState> store) async {
    print('Async Set Loading $loading');
    store.dispatch(SetLoading(loading));
  };
}
