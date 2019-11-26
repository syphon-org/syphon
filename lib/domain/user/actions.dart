import 'dart:convert';
import 'package:Tether/global/libs/matrix/registration.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

// Domain
import 'package:Tether/domain/index.dart';
import './model.dart';

const HOMESERVER_SEARCH_SERVICE =
    'https://www.hello-matrix.net/public_servers.php?format=json&only_public=true';

final PROTOCOL = DotEnv().env['PROTOCOL'];

class SetLoading {
  final bool loading;
  SetLoading({this.loading});
}

class SetCreating {
  final bool creating;
  SetCreating({this.creating});
}

class SetUser {
  final User user;
  SetUser({this.user});
}

class SetHomeserver {
  final dynamic homeserver;
  SetHomeserver({this.homeserver});
}

class SetHomeserverValid {
  final bool valid;
  SetHomeserverValid({this.valid});
}

class SetUsername {
  final String username;
  SetUsername({this.username});
}

class SetUsernameValid {
  final bool valid;
  SetUsernameValid({this.valid});
}

class SetPassword {
  final String password;
  SetPassword({this.password});
}

class SetPasswordValid {
  final bool valid;
  SetPasswordValid({this.valid});
}

class ResetOnboarding {}

ThunkAction<AppState> initAuthObserver() {
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(loading: true));

    store.dispatch(SetLoading(loading: false));
  };
}

ThunkAction<AppState> createUser() {
  // return (dispatch, state) =>
  return (Store<AppState> store) async {
    // TODO: call out to matrix here
    store.dispatch(SetLoading(loading: true));
    store.dispatch(SetCreating(creating: true));

    print('Creating User...');
    final userStore = store.state.userStore;

    final registerUserRequest = buildRegisterUserRequest(
      homeserver: userStore.homeserver,
      username: userStore.username,
      password: userStore.password,
      type: store.state.userStore.loginType,
    );

    final url = "$PROTOCOL${registerUserRequest['url']}";
    final body = json.encode(registerUserRequest['body']);

    print("$url, $body");
    final response = await http.post(
      url,
      body: body,
    );

    final data = json.decode(response.body);
    print(data);

    // new Timer(new Duration(seconds: 3), () {
    //   store.dispatch(SetUser(
    //       user: User(
    //           id: 123,
    //           username: "Testing",
    //           accessToken: 'Testing',
    //           homeserver: "192.168.1.2")));
    // });

    store.dispatch(SetCreating(creating: false));
    store.dispatch(SetLoading(loading: false));
    store.dispatch(ResetOnboarding());
  };
}

ThunkAction<AppState> setLoading(bool loading) {
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(loading: loading));
  };
}

ThunkAction<AppState> selectHomeserver({dynamic homeserver}) {
  return (Store<AppState> store) async {
    store.dispatch(SetHomeserverValid(valid: true));
    store.dispatch(SetHomeserver(homeserver: homeserver['hostname']));
  };
}

ThunkAction<AppState> setHomeserver({String homeserver}) {
  return (Store<AppState> store) async {
    store.dispatch(
        SetHomeserverValid(valid: homeserver != null && homeserver.length > 0));
    store.dispatch(SetHomeserver(homeserver: homeserver));
  };
}

ThunkAction<AppState> setUsername({String username}) {
  return (Store<AppState> store) async {
    store.dispatch(
        SetUsernameValid(valid: username != null && username.length > 0));
    store.dispatch(SetUsername(username: username));
  };
}

ThunkAction<AppState> setPassword({String password}) {
  return (Store<AppState> store) async {
    store.dispatch(
        SetPasswordValid(valid: password != null && password.length > 0));
    store.dispatch(SetPassword(password: password));
  };
}
