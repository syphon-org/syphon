import 'package:syphon/domain/index.dart';
import './model.dart';

List<Alert> alerts(AppState state) {
  return state.alertsStore.alerts;
}
