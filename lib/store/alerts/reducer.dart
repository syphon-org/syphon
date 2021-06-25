import './actions.dart';
import './model.dart';

AlertsStore alertsReducer(
    [AlertsStore state = const AlertsStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetLoading:
      return state.copyWith(loading: action.loading);
    case SetAlertsObserver:
      return state.copyWith(alertsObserver: action.alertsObserver);
    case AddAlert:
      final List<Alert> alerts = List<Alert>.from(state.alerts);
      alerts.add(action.alert);
      return state.copyWith(alerts: alerts);
    case RemoveAlert:
      List<Alert> alerts = List<Alert>.from(state.alerts);
      alerts = alerts
          .where((alert) => alert.message != action.alert.message)
          .toList();
      return state.copyWith(alerts: alerts);
    default:
      return state;
  }
}
