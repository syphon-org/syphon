import 'dart:convert';

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:Tether/domain/index.dart';

import 'package:Tether/global/libs/hive.dart';
import 'package:Tether/global/libs/matrix/index.dart';

import 'package:http/http.dart' as http;

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

class SetHomeservers {
  final List<dynamic> homeservers;

  SetHomeservers({this.homeservers});
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

ThunkAction<AppState> fetchHomeservers() {
  return (Store<AppState> store) async {
    var response = await http.get(HOMESERVER_SEARCH_SERVICE);

    print(json.decode(response.body));
  };
}

ThunkAction<AppState> searchHomeservers({String searchText}) {
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(loading: true));
    List<dynamic> results = store.state.userStore.homeservers.where(
        (homeserver) =>
            homeserver.hostname.contains(searchText) ||
            homeserver.description.contains(searchText));
    store.dispatch(SetHomeservers(homeservers: results));
    store.dispatch(SetLoading(loading: false));
  };
}
