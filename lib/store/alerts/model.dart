import 'dart:async';

class Alert {
  final String type;
  final String message;
  final Duration duration;
  final Error error;

  const Alert({
    this.type = 'warning',
    this.message = 'This is a warning',
    this.duration = const Duration(milliseconds: 3000),
    this.error,
  });
}

class AlertsStore {
  final bool loading;
  final List<Alert> alerts;
  final StreamController<Alert> alertsObserver;

  const AlertsStore({
    this.loading = false,
    this.alertsObserver,
    this.alerts = const [],
  });

  AlertsStore copyWith({
    loading,
    alerts,
    alertsObserver,
  }) {
    return AlertsStore(
      loading: loading ?? this.loading,
      alerts: alerts ?? this.alerts,
      alertsObserver: alertsObserver ?? this.alertsObserver,
    );
  }

  @override
  int get hashCode =>
      loading.hashCode ^ alerts.hashCode ^ alertsObserver.hashCode;

  Stream<Alert> get onAlertsChanged => alertsObserver.stream;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertsStore &&
          runtimeType == other.runtimeType &&
          loading == other.loading &&
          alertsObserver == other.alertsObserver &&
          alerts == other.alerts;

  @override
  String toString() {
    return '{loading: $loading, alerts: $alerts}';
  }
}
