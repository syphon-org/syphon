import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

// Domain
import 'package:Tether/domain/index.dart';
import 'package:Tether/global/libs/matrix/auth.dart';
import './model.dart';

const HOMESERVER_SEARCH_SERVICE =
    'https://www.hello-matrix.net/public_servers.php?format=json&only_public=true';

final protocol = DotEnv().env['PROTOCOL'];

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

class ResetUser {}

ThunkAction<AppState> initAuthObserver() {
  // return (dispatch, state) =>
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(loading: true));

    store.dispatch(SetLoading(loading: false));
  };
}

ThunkAction<AppState> loginUser() {
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(loading: true));

    final userStore = store.state.userStore;
    final username = store.state.userStore.username;
    final password = store.state.userStore.password;
    final homeserver = store.state.userStore.homeserver;

    final loginUserRequest = buildLoginUserRequest(
      type: "m.login.password",
      username: username,
      password: password,
    );

    final url =
        "$protocol${userStore.homeserver}:8008/${loginUserRequest['url']}";
    final body = json.encode(loginUserRequest['body']);

    final response = await http.post(url, body: body);

    final data = json.decode(response.body);

    print('Login User $data');
    store.dispatch(SetUser(
        user: User(
      userId: data['user_id'],
      deviceId: data['device_id'],
      accessToken: data['access_token'],
      homeserver: homeserver, // use homeserver from login call param instead
    )));

    store.dispatch(SetLoading(loading: false));
    store.dispatch(ResetOnboarding());
  };
}

ThunkAction<AppState> logoutUser() {
  return (Store<AppState> store) async {
    final accessToken = store.state.userStore.user.accessToken;
    final homeserver = "192.168.1.2" ?? store.state.userStore.user.homeserver;

    store.dispatch(SetLoading(loading: true));
    final logoutUserRequest = buildLogoutUserRequest(accessToken: accessToken);

    final url = "$protocol$homeserver:8008/${logoutUserRequest['url']}";

    final response = await http.post(
      url,
    );

    final data = json.decode(response.body);
    print("Logut Data $data");
    store.dispatch(ResetUser());
  };
}

ThunkAction<AppState> createUser() {
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(loading: true));
    store.dispatch(SetCreating(creating: true));
    final username = store.state.userStore.username;
    final password = store.state.userStore.password;
    final loginType = store.state.userStore.loginType;
    final homeserver = store.state.userStore.homeserver;

    final registerUserRequest = buildRegisterUserRequest(
      username: username,
      password: password,
      type: loginType,
    );

    final url = "$protocol$homeserver:8008/${registerUserRequest['url']}";
    final body = json.encode(registerUserRequest['body']);

    print("$url, $body");
    final response = await http.post(url, body: body);

    final data = json.decode(response.body);

    store.dispatch(SetUser(
        user: User(
      userId: data['user_id'],
      deviceId: data['device_id'],
      accessToken: data['access_token'],
      homeserver:
          homeserver, // TODO: use homeserver from login call param instead in dev
    )));

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
