import 'package:flutter/material.dart';
import 'package:syphon/store/index.dart';

String selectKeyBackupSchedule(AppState state) {
  final schedule = state.settingsStore.privacySettings.keyBackupInterval;

  if (schedule.inHours == 1) {
    return 'Every hour';
  } else if (schedule.inHours == 6) {
    return 'Every 6 hours';
  } else if (schedule.inHours == 12) {
    return 'Every 12 hours';
  } else if (schedule.inDays == 1) {
    return 'Every Day';
  } else if (schedule.inDays == 7) {
    return 'Every Week';
  } else if (schedule.inDays == 29) {
    return 'Every Month';
  } else {
    return 'Manual Only';
  }
}
