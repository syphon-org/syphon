import 'dart:async';

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:Tether/store/index.dart';

import './model.dart';

class SetLoading {
  final bool loading;
  SetLoading({this.loading});
}

class SetAlertsObserver {
  final StreamController<Alert> alertsObserver;
  SetAlertsObserver({this.alertsObserver});
}

class AddAlert {
  final Alert alert;
  AddAlert({this.alert});
}

class RemoveAlert {
  final Alert alert;
  RemoveAlert({this.alert});
}

ThunkAction<AppState> testAlerts({type, message}) {
  return (Store<AppState> store) async {
    final alertsObserver = store.state.alertsStore.alertsObserver;
    final alert =
        Alert(type: 'warning', message: 'testing alert messages, hi! :D');

    // Test adding alert from observer and store
    // TODO: consider the observer add() in the reducer
    store.dispatch(AddAlert(alert: alert));
    alertsObserver.add(alert);

    Timer(Duration(milliseconds: 1000), () {
      store.dispatch(RemoveAlert(alert: alert));
    });
  };
}

ThunkAction<AppState> addAlert({type, message}) {
  return (Store<AppState> store) async {
    print('[addAlert] $type : $message');
    final alertsObserver = store.state.alertsStore.alertsObserver;
    final alert = new Alert(type: type, message: message);
    store.dispatch(AddAlert(alert: alert));
    alertsObserver.add(alert);
  };
}

ThunkAction<AppState> startAlertsObserver() {
  return (Store<AppState> store) async {
    if (store.state.alertsStore.alertsObserver != null) {
      throw 'Cannot call startAlertsObserver with an existing instance';
    }

    store.dispatch(
      SetAlertsObserver(alertsObserver: StreamController<Alert>.broadcast()),
    );
  };
}

ThunkAction<AppState> stopAlertsObserver() {
  return (Store<AppState> store) async {
    store.state.alertsStore.alertsObserver.close();
  };
}
