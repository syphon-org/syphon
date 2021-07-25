import 'dart:async';

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/model.dart';

class SetContextObserver {
  final StreamController<User?> contextObserver;
  SetContextObserver({required this.contextObserver});
}

class AddAvailableUser {
  User availableUser;
  AddAvailableUser({required this.availableUser});
}

class RemoveAvailableUser {
  User availableUser;
  RemoveAvailableUser({required this.availableUser});
}

ThunkAction<AppState> startContextObserver() {
  return (Store<AppState> store) async {
    final contextObserver = store.state.authStore.contextObserver;
    if (contextObserver != null && !contextObserver.isClosed) {
      throw 'Cannot call startContextObserver with an existing instance';
    }

    store.dispatch(SetContextObserver(
      contextObserver: StreamController<User?>.broadcast(),
    ));
  };
}

ThunkAction<AppState> addAvailableUser(User user) {
  return (Store<AppState> store) async {
    // Remove all sensitive data about user (like accessToken)
    await store.dispatch(AddAvailableUser(
      availableUser: user.copyWith(
        accessToken: '',
      ),
    ));
  };
}

ThunkAction<AppState> removeAvailableUser(User user) {
  return (Store<AppState> store) async {
    // Remove all sensitive data about user (like accessToken)
    await store.dispatch(RemoveAvailableUser(
      availableUser: user.copyWith(
        accessToken: '',
      ),
    ));
  };
}

ThunkAction<AppState> stopContextObserver() {
  return (Store<AppState> store) async {
    final contextObserver = store.state.authStore.contextObserver;
    if (contextObserver != null) {
      contextObserver.close();
    }
  };
}
