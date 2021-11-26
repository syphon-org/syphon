import 'dart:async';

import 'package:equatable/equatable.dart';

class Alert {
  final String type;
  final String? message;
  final Duration duration;
  final String? error;
  final String? action;
  final bool offline;

  final Function? onAction;

  const Alert({
    this.type = 'warning',
    this.message = '',
    this.duration = const Duration(milliseconds: 8000),
    this.error,
    this.action,
    this.onAction,
    this.offline = false,
  });
}

class AlertsStore extends Equatable {
  final bool loading;
  final List<Alert> alerts;
  final StreamController<Alert>? alertsObserver;

  Stream<Alert> get onAlertsChanged => alertsObserver!.stream;

  const AlertsStore({
    this.loading = false,
    this.alertsObserver,
    this.alerts = const [],
  });

  @override
  List<Object> get props => [
        loading,
        alerts,
      ];

  AlertsStore copyWith({
    loading,
    alerts,
    alertsObserver,
  }) =>
      AlertsStore(
        loading: loading ?? this.loading,
        alerts: alerts ?? this.alerts,
        alertsObserver: alertsObserver ?? this.alertsObserver,
      );
}
