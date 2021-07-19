import 'dart:async';

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/model.dart';

class SetContextObserver {
  final StreamController<User?> contextObserver;

  SetContextObserver({
    required this.contextObserver,
  });
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

ThunkAction<AppState> stopContextObserver() {
  return (Store<AppState> store) async {
    final contextObserver = store.state.authStore.contextObserver;
    if (contextObserver != null) {
      contextObserver.close();
    }
  };
}
