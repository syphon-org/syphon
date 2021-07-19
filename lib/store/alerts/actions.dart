import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

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
    store.dispatch(addInfo(message: tr('alert-feature-in-progress')));
  };
}

ThunkAction<AppState> addInfo({
  type = 'info',
  origin = 'Unknown',
  message,
  error,
}) {
  return (Store<AppState> store) async {
    debugPrint('[$origin] $type : $message');

    final alertsObserver = store.state.alertsStore.alertsObserver!;
    final alert = Alert(type: type, message: message, error: error);
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
    debugPrint('[$origin|confirm] $message');

    final alertsObserver = store.state.alertsStore.alertsObserver!;
    final alert = Alert(type: type, message: message, error: error.toString());
    store.dispatch(AddAlert(alert: alert));
    alertsObserver.add(alert);
  };
}

ThunkAction<AppState> addAlert({
  type = 'warning',
  required String origin,
  String message = '',
  error,
}) {
  return (Store<AppState> store) async {
    debugPrint('[$origin] ${error.toString()}');

    final alertsObserver = store.state.alertsStore.alertsObserver!;
    final alert =
        Alert(type: type, message: message.isNotEmpty ? message : error.toString(), error: error.toString());
    store.dispatch(AddAlert(alert: alert));
    alertsObserver.add(alert);
  };
}
