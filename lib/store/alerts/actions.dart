import 'dart:async';

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/strings.dart';

import 'package:syphon/store/index.dart';
import './model.dart';

class SetLoading {
  final bool? loading;
  SetLoading({this.loading});
}

class SetAlertsObserver {
  final StreamController<Alert>? alertsObserver;
  SetAlertsObserver({this.alertsObserver});
}

class AddAlert {
  final Alert? alert;
  AddAlert({this.alert});
}

class AddSuccess {
  final Alert? alert;
  AddSuccess({this.alert});
}

class RemoveAlert {
  final Alert? alert;
  RemoveAlert({this.alert});
}

ThunkAction<AppState> startAlertsObserver() {
  return (Store<AppState> store) async {
    final alertsObserver = store.state.alertsStore.alertsObserver;

    if (alertsObserver != null && !alertsObserver.isClosed) {
      throw 'Cannot call startAlertsObserver with an existing instance';
    }

    store.dispatch(SetAlertsObserver(
      alertsObserver: StreamController<Alert>.broadcast(),
    ));
  };
}

ThunkAction<AppState> stopAlertsObserver() {
  return (Store<AppState> store) async {
    store.state.alertsStore.alertsObserver!.close();
  };
}

ThunkAction<AppState> addInProgress() {
  return (Store<AppState> store) async {
    store.dispatch(addInfo(message: Strings.alertFeatureInProgress));
  };
}

ThunkAction<AppState> addInfo({
  type = 'info',
  origin = 'Unknown',
  message,
  error,
  String? action,
  Function? onAction,
}) {
  return (Store<AppState> store) async {
    printInfo('[INFO] [$origin] $message');

    final alertsObserver = store.state.alertsStore.alertsObserver!;
    final alert = Alert(
      type: type,
      message: message,
      error: error,
      action: action,
      onAction: onAction,
    );
    store.dispatch(AddAlert(alert: alert));
    alertsObserver.add(alert);
  };
}

ThunkAction<AppState> addConfirmation({
  String type = 'success',
  String origin = 'Unknown',
  String? message,
  error,
}) {
  return (Store<AppState> store) async {
    printInfo('[CONFIRMATION] [$origin] $message');

    final alertsObserver = store.state.alertsStore.alertsObserver!;
    final alert = Alert(type: type, message: message, error: error.toString());
    store.dispatch(AddAlert(alert: alert));
    alertsObserver.add(alert);
  };
}

ThunkAction<AppState> addAlert({
  required String origin,
  type = 'warning',
  String message = '',
  dynamic error,
}) {
  return (Store<AppState> store) async {
    final errorMessage = error?.toString() ?? '';

    printError('[ERROR] [$origin] $errorMessage');

    if (message.isEmpty && error == null) return;

    final alertsObserver = store.state.alertsStore.alertsObserver!;
    final alert = Alert(
      type: type,
      message: message.isNotEmpty ? message : errorMessage,
      error: errorMessage,
    );
    store.dispatch(AddAlert(alert: alert));
    alertsObserver.add(alert);
  };
}
