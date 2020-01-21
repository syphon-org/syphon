import 'dart:async';
import 'dart:convert';
import 'package:Tether/domain/rooms/actions.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

// Domain
import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/alerts/actions.dart';
import 'package:Tether/global/libs/matrix/auth.dart';
import 'package:Tether/global/libs/matrix/user.dart';
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

class SetAuthObserver {
  final StreamController authObserver;
  SetAuthObserver({this.authObserver});
}

class ResetOnboarding {}

class ResetUser {}

ThunkAction<AppState> startAuthObserver() {
  return (Store<AppState> store) async {
    if (store.state.userStore.authObserver != null) {
      throw 'Cannot call startAuthObserver with an existing instance!';
    }

    store.dispatch(
      SetAuthObserver(authObserver: StreamController<User>.broadcast()),
    );

    final user = store.state.userStore.user;
    final Function onAuthStateChanged = (user) {
      if (user != null && user.accessToken != null) {
        store.dispatch(fetchUserProfile());
        store.dispatch(startRoomsObserver());
      } else {
        store.dispatch(stopRoomsObserver());
      }
    };

    // init current auth state and set auth state listener
    onAuthStateChanged(user);
    store.state.userStore.onAuthStateChanged.listen(onAuthStateChanged);
  };
}

ThunkAction<AppState> stopAuthObserver() {
  return (Store<AppState> store) async {
    if (store.state.userStore.authObserver != null) {
      store.state.userStore.authObserver.close();
      store.dispatch(SetAuthObserver(authObserver: null));
    }
  };
}

ThunkAction<AppState> loginUser() {
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(loading: true));

    try {
      final authObserver = store.state.userStore.authObserver;

      final request = buildLoginUserRequest(
        type: "m.login.password",
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        username: store.state.userStore.username,
        password: store.state.userStore.password,
      );

      final response = await http.post(
        request['url'],
        body: json.encode(
          request['body'],
        ),
      );

      final data = json.decode(response.body);

      if (data['errcode'] == 'M_FORBIDDEN') {
        throw Exception('Invalid credentials, confirm and try again');
      }

      if (data['errcode'] != null) {
        throw Exception(data['error']);
      }

      store.dispatch(SetUser(
          user: User(
        userId: data['user_id'],
        deviceId: data['device_id'],
        accessToken: data['access_token'],
        homeserver: store.state.userStore
            .homeserver, // use homeserver from login call param instead
      )));

      authObserver.add(store.state.userStore.user);

      store.dispatch(ResetOnboarding());
    } catch (error) {
      print('loginUser failure : $error');
      store.dispatch(addAlert(type: 'warning', message: error.message));
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> fetchUserProfile() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final user = store.state.userStore.user;

      final request = buildUserProfileRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
        userId: user.userId,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      final data = json.decode(response.body);

      store.dispatch(SetUser(
        user: user.copyWith(
          displayName: data['displayname'],
          avatarUrl: data['avatar_url'],
        ),
      ));
    } catch (error) {
      print(error);
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> logoutUser() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final authObserver = store.state.userStore.authObserver;

      final request = buildLogoutUserRequest(
        protocol: protocol,
        homeserver: store.state.userStore.user.homeserver,
        accessToken: store.state.userStore.user.accessToken,
      );

      final response = await http.post(
        request['url'],
        headers: request['headers'],
      );

      json.decode(response.body);

      authObserver.add(null);
      store.dispatch(ResetUser());
    } catch (error) {
      print(error);
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> createUser() {
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(loading: true));
    store.dispatch(SetCreating(creating: true));

    final loginType = store.state.userStore.loginType;

    final request = buildRegisterUserRequest(
      protocol: protocol,
      homeserver: store.state.userStore.homeserver,
      username: store.state.userStore.username,
      password: store.state.userStore.password,
      type: loginType,
    );

    final response = await http.post(
      request['url'],
      body: request['body'],
    );

    final data = json.decode(response.body);

    // TODO: use homeserver from login call param instead in dev
    store.dispatch(SetUser(
        user: User(
      userId: data['user_id'],
      deviceId: data['device_id'],
      accessToken: data['access_token'],
      homeserver: store.state.userStore.homeserver,
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
    store.dispatch(SetHomeserver(homeserver: homeserver.trim()));
  };
}

ThunkAction<AppState> setUsername({String username}) {
  return (Store<AppState> store) async {
    store.dispatch(
        SetUsernameValid(valid: username != null && username.length > 0));
    store.dispatch(SetUsername(username: username.trim()));
  };
}

ThunkAction<AppState> setPassword({String password}) {
  return (Store<AppState> store) async {
    store.dispatch(
        SetPasswordValid(valid: password != null && password.length > 0));
    store.dispatch(SetPassword(password: password.trim()));
  };
}
